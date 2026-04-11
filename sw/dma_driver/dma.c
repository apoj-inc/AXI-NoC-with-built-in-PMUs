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
uint64_t b0_start, b0_size, b2_start, b2_size;

// Device file globs
static dev_t driver_dev_nr;
static struct cdev driver_cdev;
static struct class *driver_class;

// DMA pointer globs
static void *cpu_addr;
static dma_addr_t dma_handle;


static ssize_t read_from_pci(struct file *filp, char __user *user_buf, size_t len, loff_t *off) {
    uint32_t not_copied;
    void __iomem *hwmem;

    hwmem = ioremap(b2_start, b2_size);

    iowrite64(dma_handle, hwmem);
    iowrite64(len, hwmem+(8<<4));
    iowrite64(1, hwmem+(12<<4));
    printk(KERN_INFO "hdlnocgen_c5p_driver: DMA write of %lu bytes issued\n", len);
    fsleep(10);

    not_copied = copy_to_user((void *)user_buf, cpu_addr, len);
    if (not_copied) {
        printk(KERN_WARNING "hdlnocgen_c5p_driver: %lu bytes requested, only %lu copied", len, len - not_copied);
    }

	return len - not_copied;
}

static ssize_t write_to_pci(struct file *filp, const char __user *user_buf, size_t len, loff_t *off) {
    uint32_t not_copied;
    void __iomem *hwmem;

    hwmem = ioremap(b2_start, b2_size);

    not_copied = copy_from_user(cpu_addr, (void *)user_buf, len);
    if (not_copied) {
        printk(KERN_WARNING "hdlnocgen_c5p_driver: %lu bytes requested, only %lu copied", len, len - not_copied);
    }
    iowrite64(dma_handle, hwmem);
    iowrite64(len, hwmem+(8<<4));
    iowrite64(1, hwmem+(16<<4));
    printk(KERN_INFO "hdlnocgen_c5p_driver: DMA read of %lu bytes issued\n", len);
    fsleep(10);

	return not_copied;
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


static int hdlnocgen_dma_probe(struct pci_dev *pdev, const struct pci_device_id *ent) {
    uint16_t vendor, device;
    int err;

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


    pci_read_config_word(pdev, PCI_VENDOR_ID, &vendor);
    pci_read_config_word(pdev, PCI_DEVICE_ID, &device);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Device vid: 0x%X\n", vendor);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Device pid: 0x%X\n", device);

    // PCIe device BAR[0, 2] setup
    err = pci_request_region(pdev, 0, DRIVER_NAME);
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to reserve BAR0\n");
        goto destroy_device_file;
    }
    err = pci_request_region(pdev, 2, DRIVER_NAME);
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to reserve BAR2\n");
        goto pci_release_bar0;
    }
    err = pci_enable_device_mem(pdev);
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to enable PCIe device's memory\n");
        goto pci_release_bar2;
    }

    // Get BAR[0, 2] addresses
    b0_start = pci_resource_start(pdev, 0);
    b0_size = pci_resource_len(pdev, 0);
    b2_start = pci_resource_start(pdev, 2);
    b2_size = pci_resource_len(pdev, 2);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[0]: 0x%llx-0x%llx\n", b0_start, b0_start + b0_size - 1);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[2]: 0x%llx-0x%llx\n", b2_start, b2_start + b2_size - 1);


    // Register MSIs
    err = pci_alloc_irq_vectors(pdev, 1, 1, PCI_IRQ_MSI);
    if (err < 0) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to register PCIe interrupts\n");
        goto pci_disable;
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: Allocated %d interrupts using MSIs\n", err);


    // DMA address mask setup
    err = dma_set_mask_and_coherent(&(pdev->dev), DMA_BIT_MASK(64));
    if (err) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to set DMA mask\n");
        goto msi_free;
    }

    // Allocate DMA buffer
    cpu_addr = dma_alloc_coherent(&(pdev->dev), DMA_BUFFER_SIZE, &dma_handle, GFP_KERNEL);
    if (!cpu_addr) {
        printk(KERN_ERR "hdlnocgen_c5p_driver: Failed to allocate %llu bytes for DMA buffer\n", (uint64_t)DMA_BUFFER_SIZE);
        err = ENOENT;
        goto dma_free;
    }
    printk(KERN_INFO "hdlnocgen_c5p_driver: Created %d bytes of dma bytes. CPU addr - 0x%p, DMA addr - 0x%llx\n", DMA_BUFFER_SIZE, cpu_addr, dma_handle);

    // Set PCIe as master
    pci_set_master(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Bus mastered by PCIe device\n");

    return 0;

dma_free:
    dma_free_coherent(&(pdev->dev), DMA_BUFFER_SIZE, cpu_addr, dma_handle);
msi_free:
    pci_free_irq_vectors(pdev);
pci_disable:
    pci_disable_device(pdev);
pci_release_bar2:
    pci_release_region(pdev, 2);
pci_release_bar0:
    pci_release_region(pdev, 0);
destroy_device_file:
    device_destroy(driver_class, driver_dev_nr);
delete_driver_class:
	class_unregister(driver_class);
	class_destroy(driver_class);
delete_driver_cdev:
	cdev_del(&driver_cdev);
free_driver_dev_nr:
    unregister_chrdev_region(driver_dev_nr, MINORMASK + 1);

    return err;
}

static void hdlnocgen_dma_remove(struct pci_dev *pdev) {

    pci_clear_master(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: PCIe device unmastered\n");
    pci_free_irq_vectors(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: PCIe MSIs released\n");
    dma_free_coherent(&(pdev->dev), DMA_BUFFER_SIZE, cpu_addr, dma_handle);
    printk(KERN_INFO "hdlnocgen_c5p_driver: DMA buffer released\n");
    pci_disable_device(pdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: PCIe device disabled\n");
    pci_release_region(pdev, 2);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[2] released\n");
    pci_release_region(pdev, 0);
    printk(KERN_INFO "hdlnocgen_c5p_driver: BAR[0] released\n");

    device_destroy(driver_class, driver_dev_nr);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Destroyed device file hdlnocgen_c5p0\n");
	class_unregister(driver_class);
	class_destroy(driver_class);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Destroyed class hdlnocgen_c5p_class\n");
	cdev_del(&driver_cdev);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Deleted chrdev\n");
    unregister_chrdev_region(driver_dev_nr, MINORMASK + 1);
    printk(KERN_INFO "hdlnocgen_c5p_driver: Unregistered chrdev region\n");

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
