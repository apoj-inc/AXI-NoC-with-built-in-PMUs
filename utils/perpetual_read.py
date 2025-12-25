import serial

with serial.Serial('/dev/ttyUSB0', 9600) as ser:

    if not ser.is_open:
        raise Exception('KAAAAL')
    else:
        print(ser.name)
    
    while True:
        a = 0
        b = 0
        
        for i in range(8):
            a = a + (int.from_bytes(ser.read(), 'little')) * (256 ** i)
        print(a)
        for i in range(8):
            b = b + (int.from_bytes(ser.read(), 'little')) * (256 ** i)
        print(b)