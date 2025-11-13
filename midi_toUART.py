import rtmidi
import serial

def sendToFPGA(msg, ser): 
    message, deltatime = msg  
    midi_note_status = 1 if message[0] == 144 else 0  
    midi_note_address = message[1]
    
    # 1 byte of information: top 7 bits are note address in LUT and LSB is note status 1 = ON 0 = OFF
    msg_note_packet = (midi_note_address << 1) | midi_note_status 
    
    # Send as a single byte 
    ser.write(bytes([msg_note_packet]))  
    print(f"Sent to FPGA: 0x{msg_note_packet:02X} (note: {midi_note_address}, status: {midi_note_status})")

def main():
    # Opening Serial port communication with FPGA at 115200 baud
    ser = serial.Serial(
        port='/dev/tty.usbserial-1301',
        baudrate=115200,      
        bytesize=serial.EIGHTBITS,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        timeout=1  
    )
    
    midiin = rtmidi.MidiIn()
    
    # List available ports
    available_ports = midiin.get_ports()
    print("Available MIDI ports:")
    for i, port in enumerate(available_ports):
        print(f"{i}: {port}")
    
    # Connect to IAC Driver
    if available_ports:
        iac_port = next((i for i, p in enumerate(available_ports) if "IAC" in p), 0)
        midiin.open_port(iac_port)
        print(f"\nListening on: {available_ports[iac_port]}")
        
        print("Play notes in Reaper - Press Ctrl+C to quit\n")
        
        try:
            while True:
                msg = midiin.get_message()
                if msg:
                    message, deltatime = msg
                    print(f"MIDI: {message} (time: {deltatime})")
                    sendToFPGA(msg, ser)
        except KeyboardInterrupt:
            print("\nExiting...")
    
    midiin.close_port()
    ser.close()

if __name__ == "__main__":
    main()
