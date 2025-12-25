import serial
import time
import random

with serial.Serial('/dev/ttyUSB0', 9600) as ser:

    if not ser.is_open:
        raise Exception('KAAAAL')
    else:
        print(ser.name)

    while True:

        ser.write(int.to_bytes(2, 1, 'little'))
        ser.write(int.to_bytes(32, 1, 'little'))

        for i in range(32):
            ser.write(int.to_bytes(4, 1, 'little'))
            ser.write(int.to_bytes(2, 1, 'little'))
            ser.write(int.to_bytes(random.randint(1, 16), 1, 'little'))
            ser.write(int.to_bytes(3, 1, 'little'))

        ser.write(int.to_bytes(6, 1, 'little'))
        print("written")
        time.sleep(1)

        ser.write(int.to_bytes(7, 1, 'little'))
        ser.write(int.to_bytes(2, 1, 'little'))
        ser.write(int.to_bytes(15, 1, 'little'))
        print("read 1")
        time.sleep(1)

        ser.write(int.to_bytes(7, 1, 'little'))
        ser.write(int.to_bytes(2, 1, 'little'))
        ser.write(int.to_bytes(17, 1, 'little'))
        print("read 2")
        time.sleep(1)