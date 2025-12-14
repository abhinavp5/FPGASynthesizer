import rtmidi
import serial

def sendToFPGA(msg, ser): 
    message, deltatime = msg
    
    # Safety check: Ensure message has at least 3 bytes 
    # (rtmidi usually expands messages, but this prevents IndexError crashes)
    if len(message) < 3:
        return

    # Check if it's a Note On (144/0x90) or Note Off (128/0x80)
    # We filter out other messages (like Pitch Bend or Control Change) for now
    status = message[0] & 0xF0 # Get the command nibble (0x90 or 0x80)
    
    if status == 0x90 or status == 0x80:
        # Extract raw bytes
        status_byte = message[0]
        note_byte = message[1]
        velocity_byte = message[2]

        # Send all 3 bytes to the FPGA
        # The FPGA FSM needs all 3 to trigger "msg_ready"
        ser.write(bytes([status_byte, note_byte, velocity_byte]))  
        
        print(f"Sent raw MIDI: {status_byte} {note_byte} {velocity_byte}")
def main():
    # Opening Serial port communication with FPGA at 115200 baud
    ser = serial.Serial(
        port='/dev/cu.usbserial-11101',
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
