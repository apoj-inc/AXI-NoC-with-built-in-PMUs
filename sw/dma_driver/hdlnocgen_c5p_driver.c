#include <linux/types.h>
#include <linux/module.h>
#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/pci.h>
#include <linux/device.h>
#include <linux/dma-mapping.h>
#include <linux/io-64-nonatomic-lo-hi.h>
#include <linux/delay.h>
#include <linux/fs.h>
#include <linux/cdev.h>

#define DRIVER_NAME "hdlnocgen_c5p_driver"
#define DMA_BUFFER_SIZE 4096

// BAR[0, 2] address and size globs
uint64_t b0_start, b0_size;
uint64_t b2_start, b2_size;

// Device file globs
static dev_t driver_dev_nr;
static struct cdev driver_cdev;
static struct class *driver_class;

// DMA config globs
static uint16_t dma_channel_count;
void __iomem *bar0_ptr, *bar2_ptr;
int irq_index[16] = {-1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1};
int irq_flags[16] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

// DMA pointer globs
static void *cpu_addr[16];
static dma_addr_t dma_handle[16];


static ssize_t read_from_pci(struct file *filp, char __user *user_buf, size_t len, loff_t *off) {
    /*
    uint32_t not_copied;
    void __iomem *hwmem;

    hwmem = ioremap(b0_start, b0_size);

    iowrite64(dma_handle, hwmem);
    iowrite64(len, hwmem+8);
    iowrite64(1, hwmem+12);
    printk(KERN_INFO "hdlnocgen_c5p_driver: DMA write of %lu bytes issued\n", len);
    fsleep(10);

    not_copied = copy_to_user((void *)user_buf, cpu_addr, len);
    if (not_copied) {
        printk(KERN_WARNING "hdlnocgen_c5p_driver: %lu bytes requested, only %lu copied", len, len - not_copied);
    }

	return len - not_copied;
    */
    return 0;
}

static ssize_t write_to_pci(struct file *filp, const char __user *user_buf, size_t len, loff_t *off) {
    /*
    uint32_t not_copied;
    void __iomem *hwmem;

    hwmem = ioremap(b0_start, b0_size);

    not_copied = copy_from_user(cpu_addr, (void *)user_buf, len);
    if (not_copied) {
        printk(KERN_WARNING "hdlnocgen_c5p_driver: %lu bytes requested, only %lu copied", len, len - not_copied);
    }
    iowrite64(dma_handle, hwmem);
    iowrite64(len, hwmem+8);
    iowrite64(1, hwmem+16);
    printk(KERN_INFO "hdlnocgen_c5p_driver: DMA read of %lu bytes issued\n", len);
    fsleep(10);

	return not_copied;
    */
    return 0;
}


static struct file_operations fops = {
	.read = read_from_pci,
    .write = write_to_pci
};


static struct pci_device_id my_driver_id_table[] = {
    { PCI_DEVICE(0x1172, 0xd800) },
    { PCI_DEVICE(0x1172, 0x00ff) },
    {0,}
};
MODULE_DEVICE_TABLE(pci, my_driver_id_table);

static int hdlnocgen_dma_probe(struct pci_dev *pdev, const struct pci_device_id *ent);

static void hdlnocgen_dma_remove(struct pci_dev *pdev);


static struct pci_driver hdlnocgen_dma_driver = {
    .name = "hdlnocgen_c5p_dma",
    .id_table = my_driver_id_table,
    .probe = hdlnocgen_dma_probe,
    .remove = hdlnocgen_dma_remove
};



static irqreturn_t dma_finish(int irq, void *dev) {
    for (int i = 0; i < dma_channel_count; i++) {
        if (irq_index[i] == irq) {
            irq_flags[i] = 0;
            break;
        }
    }
    return IRQ_HANDLED;
}


static int hdlnocgen_dma_probe(struct pci_dev *pdev, const struct pci_device_id *ent) {
    uint16_t vendor, device;
    int err;


    pci_read_config_word(pdev, PCI_VENDOR_ID, &vendor);
    pci_read_config_word(pdev, PCI_DEVICE_ID, &device);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Device vid: 0x%X\n", vendor);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Device pid: 0x%X\n", device);

    // PCIe memory enable
    err = pci_enable_device_mem(pdev);
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to enable PCIe device's memory\n");
        goto pci_release_bar2;
    }

    // PCIe device BAR[0] req
    err = pci_request_region(pdev, 0, DRIVER_NAME);
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to reserve BAR0\n");
        return err;
    }
    // PCIe device BAR[2] req
    err = pci_request_region(pdev, 2, DRIVER_NAME);
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to reserve BAR2\n");
        goto pci_release_bar0;
    }

    // Get BAR[0] addresses
    b0_start = pci_resource_start(pdev, 0);
    b0_size = pci_resource_len(pdev, 0);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[0]: 0x%llx-0x%llx\n", b0_start, b0_start + b0_size - 1);
    // Get BAR[2] addresses
    b2_start = pci_resource_start(pdev, 2);
    b2_size = pci_resource_len(pdev, 2);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[2]: 0x%llx-0x%llx\n", b2_start, b2_start + b2_size - 1);

    // Remap BARs to memory
    bar0_ptr = ioremap(b0_start, b0_size);
    if (!bar0_ptr) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to ioremap BAR[0]...\n");
        err = -ENOMEM;
        goto pci_disable;
    }
    bar2_ptr = ioremap(b2_start, b2_size);
    if (!bar2_ptr) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to ioremap BAR[2]...\n");
        err = -ENOMEM;
        goto unmap_bar0;
    }

    printk(KERN_INFO "hdlnocgen_c5p_driver: Extracting configuration info...\n");
    dma_channel_count = ioread32(bar2_ptr) & 0xFFFF;
    printk(KERN_INFO "hdlnocgen_c5p_driver: Extracting done. This DMA has %hu channels\n", dma_channel_count);

    // Register MSIs
    err = pci_alloc_irq_vectors(pdev, dma_channel_count, dma_channel_count, PCI_IRQ_MSIX);
    if (err < 0) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to register PCIe interrupts\n");
        goto unmap_bar2;
    }
    else if (err != dma_channel_count) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to allocate PCIe interrupts - %hu interrupts required, but %d alocated\n", dma_channel_count, err);
        goto msi_free;
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: Allocated %d interrupts using MSIXs\n", err);


    // DMA address mask setup
    err = dma_set_mask_and_coherent(&(pdev->dev), DMA_BIT_MASK(64));
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to set DMA mask\n");
        goto msi_free;
    }

    // Allocate DMA buffers
    uint32_t next_struct_addr = (ioread32(bar2_ptr) & 0xFFFF0000) >> 16;
    printk(KERN_INFO "hdlnocgen_c5p_driver: Channel 0 struct addr is 0x%x\n", next_struct_addr);

    for (int i = 0; i < dma_channel_count; i++) {
        cpu_addr[i] = dma_alloc_coherent(&(pdev->dev), DMA_BUFFER_SIZE, &(dma_handle[i]), GFP_KERNEL);
        if (!cpu_addr[i]) {
            printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to allocate %llu bytes for DMA buffer channel %d\n", (uint64_t)DMA_BUFFER_SIZE, i);
            err = ENOENT;
            goto msi_free;
        }
        printk(KERN_INFO "hdlnocgen_c5p_driver: Created %d bytes of dma bytes. Channel - %d, CPU addr - 0x%p, DMA addr - 0x%llx\n", DMA_BUFFER_SIZE, i, cpu_addr[i], dma_handle[i]);

        iowrite32(dma_handle[i], bar2_ptr + next_struct_addr + 4);
        iowrite32(dma_handle[i] >> 32, bar2_ptr + next_struct_addr + 8);
        printk(KERN_INFO "hdlnocgen_c5p_driver: Wrote DMA addr for channel %d\n", i);

        next_struct_addr = ioread32(bar2_ptr + next_struct_addr);
        printk(KERN_INFO "hdlnocgen_c5p_driver: Channel %d struct addr is 0x%x\n", i+1, next_struct_addr);
    }

    // Set PCIe as master
    pci_set_master(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Bus mastered by PCIe device\n");

    // DMA channels setup and test
    for (int i = 0; i < dma_channel_count; i++) {
        // Set IRQ handler
        irq_index[i] = pci_irq_vector(pdev, i);
        printk(KERN_INFO "hdlnocgen_c5p_driver: IRQ for channel %d is %d\n", i, irq_index[i]);

        err = request_irq(irq_index[i], dma_finish, IRQF_TRIGGER_RISING, DRIVER_NAME, NULL);
        if (err) {
            printk(KERN_INFO "hdlnocgen_c5p_driver: Failed to register IRQ handler for channel %d\n", i);
            goto free_dma;
        }
        printk(KERN_INFO "hdlnocgen_c5p_driver: Registered IRQ handler for DMA channel %d\n", i);
    }

    for (int i = 0; i < dma_channel_count; i++) {

        printk(KERN_INFO "hdlnocgen_c5p_driver: Init DMA channel %d data...\n", i);

        // Init data
        for (int j = 0; j < DMA_BUFFER_SIZE/sizeof(uint64_t); j++) {
            ((uint64_t *)(cpu_addr[i]))[j] = j;
        }
        printk(KERN_INFO "hdlnocgen_c5p_driver: Init data - ");
        for (int j = 0; j < DMA_BUFFER_SIZE/sizeof(uint64_t); j++) {
            printk(KERN_CONT "%llu ", ((uint64_t *)(cpu_addr[i]))[j]);
        }
    }

    for (int i = 0; i < dma_channel_count; i++) {
        irq_flags[i] = 1;

        // DMA read
        iowrite64(0 | (((uint64_t)DMA_BUFFER_SIZE) << 32), bar2_ptr + 0x1008 + i*0x10);
        printk(KERN_INFO "hdlnocgen_c5p_driver: DMA channel %d read from PC command sent\n", i);
    }

    for (int i = 0; i < dma_channel_count; i++) {
        while (irq_flags[i]) {
            fsleep(1000);
        }

        printk(KERN_INFO "hdlnocgen_c5p_driver: DMA channel %d read from PC finished\n", i);
    }


    for (int i = 0; i < dma_channel_count; i++) {
        // Scramble data
        for (int j = 0; j < DMA_BUFFER_SIZE/sizeof(uint64_t); j++) {
            ((uint64_t *)(cpu_addr[i]))[j] = 0;
        }
        printk(KERN_INFO "hdlnocgen_c5p_driver: DMA channel %d scrambled data - ", i);
        for (int j = 0; j < DMA_BUFFER_SIZE/sizeof(uint64_t); j++) {
            printk(KERN_CONT "%llu ", ((uint64_t *)(cpu_addr[i]))[j]);
        }
    }


    for (int i = 0; i < dma_channel_count; i++) {
        irq_flags[i] = 1;
        iowrite64(0 | (((uint64_t)DMA_BUFFER_SIZE) << 32), bar2_ptr + 0x1000 + i*0x10);
        printk(KERN_INFO "hdlnocgen_c5p_driver: DMA channel %d write to PC command sent\n", i);
    }


    for (int i = 0; i < dma_channel_count; i++) {
        while (irq_flags[i]) {
            fsleep(1000);
        }
        printk(KERN_INFO "hdlnocgen_c5p_driver: DMA channel %d write to PC finished\n", i);
    }

    for (int i = 0; i < dma_channel_count; i++) {
        printk(KERN_INFO "hdlnocgen_c5p_driver: DMA channel %d written data - ", i);
        for (int j = 0; j < DMA_BUFFER_SIZE/sizeof(uint64_t); j++) {
            printk(KERN_CONT "%llu ", ((uint64_t *)(cpu_addr[i]))[j]);
        }
    }




/*
    // Driver device setup
    err = alloc_chrdev_region(&driver_dev_nr, 0, MINORMASK + 1, "hdlnocgen_c5p_cdev"); // get major and minor numbers allocated
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to reserve major and minor numbers\n");
        return err;
    }
    cdev_init(&driver_cdev, &fops);
    driver_cdev.owner = THIS_MODULE;

    err = cdev_add(&driver_cdev, driver_dev_nr, MINORMASK + 1);
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to create cdev\n");
        goto free_driver_dev_nr;
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: Registered cdev with Major %d starting with Minor %d\n", MAJOR(driver_dev_nr), MINOR(driver_dev_nr)); // register cdev under these numbers

    driver_class = class_create("hdlnocgen_c5p_class");
    if (!driver_class) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Could not create class hdlnocgen_c5p_class\n");
        err = -ENOMEM;
        goto delete_driver_cdev;
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: Created class hdlnocgen_c5p_class\n"); // register cdev under these numbers

    if (!device_create(driver_class, &(pdev->dev), driver_dev_nr, NULL, "hdlnocgen_c5p0")) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Could not create device file hdlnocgen_c5p0\n");
        err = -ENOMEM;
        goto delete_driver_class;
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: Created device file hdlnocgen_c5p0\n"); // register cdev under these numbers






*/
    return 0;
/*
dma_free:
    dma_free_coherent(&(pdev->dev), DMA_BUFFER_SIZE, cpu_addr, dma_handle);
destroy_device_file:
    device_destroy(driver_class, driver_dev_nr);
delete_driver_class:
	class_unregister(driver_class);
	class_destroy(driver_class);
delete_driver_cdev:
	cdev_del(&driver_cdev);
free_driver_dev_nr:
    unregister_chrdev_region(driver_dev_nr, MINORMASK + 1);
*/

free_dma:
    for (int i = 0; i < dma_channel_count; i++) {
        dma_free_coherent(&(pdev->dev), DMA_BUFFER_SIZE, cpu_addr[i], dma_handle[i]);
    }
msi_free:
    pci_free_irq_vectors(pdev);
unmap_bar2:
    iounmap(bar2_ptr);
unmap_bar0:
    iounmap(bar0_ptr);
pci_release_bar2:
    pci_release_region(pdev, 2);
pci_release_bar0:
    pci_release_region(pdev, 0);
pci_disable:
    pci_disable_device(pdev);

    return err;
}

static void hdlnocgen_dma_remove(struct pci_dev *pdev) {

    for (int i = 0; i < dma_channel_count; i++) {
        free_irq(irq_index[i], NULL);
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: Freed IRQ handlers\n");
    for (int i = 0; i < dma_channel_count; i++) {
        dma_free_coherent(&(pdev->dev), DMA_BUFFER_SIZE, cpu_addr[i], dma_handle[i]);
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: DMA buffers freed\n");
    pci_free_irq_vectors(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: PCIe MSIXs released\n");
    iounmap(bar2_ptr);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[2] unmapped\n");
    iounmap(bar0_ptr);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[0] unmapped\n");
    pci_release_region(pdev, 2);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[2] released\n");
    pci_release_region(pdev, 0);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[0] released\n");
    pci_disable_device(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: PCIe device disabled\n");

    /*
    pci_clear_master(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: PCIe device unmastered\n");
    dma_free_coherent(&(pdev->dev), DMA_BUFFER_SIZE, cpu_addr, dma_handle);
    printk(KERN_INFO "hdlnocgen_c5p_driver: DMA buffer released\n");
    device_destroy(driver_class, driver_dev_nr);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Destroyed device file hdlnocgen_c5p0\n");
	class_unregister(driver_class);
	class_destroy(driver_class);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Destroyed class hdlnocgen_c5p_class\n");
	cdev_del(&driver_cdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Deleted chrdev\n");
    unregister_chrdev_region(driver_dev_nr, MINORMASK + 1);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Unregistered chrdev region\n");
    */

}


static int __init init_hdlnocgen_dma_driver (void) {

	return pci_register_driver(&hdlnocgen_dma_driver);
}

static void __exit cleanup_hdlnocgen_dma_driver (void) {

	pci_unregister_driver(&hdlnocgen_dma_driver);
}

module_init(init_hdlnocgen_dma_driver);
module_exit(cleanup_hdlnocgen_dma_driver);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Serkhan");
MODULE_DESCRIPTION("DMA altera crap");
