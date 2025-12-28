
import sys

def patch_gif_loop(input_path, output_path):
    with open(input_path, 'rb') as f:
        data = bytearray(f.read())

    # Netscape Loop Extension Signature: 
    # Extension Introducer (0x21)
    # Application Extension Label (0xFF)
    # Block Size (0x0B)
    # App Identifier (NETSCAPE2.0)
    # Sub-block Data Size (0x03)
    # Sub-block ID (0x01)
    signature = b'\x21\xff\x0bNETSCAPE2.0\x03\x01'
    
    index = data.find(signature)
    
    if index != -1:
        print(f"Found Netscape Loop Extension at index {index}")
        # The block is: Signature (16 bytes) + Loop Count (2 bytes) + Block Terminator (0x00).
        
        # Structure detailed:
        # 0x21 (1)
        # 0xFF (1)
        # 0x0B (1)
        # NETSCAPE2.0 (11)
        # 0x03 (1)
        # 0x01 (1)
        # LO (1)
        # HI (1)
        # 0x00 (1)
        # Total: 19 bytes.
        
        del data[index:index+19]
        print("Removed Netscape Loop Extension block.")
        
        with open(output_path, 'wb') as f:
            f.write(data)
        print(f"Saved patched file to {output_path}")
        
    else:
        print("Netscape Loop Extension not found. It might already be non-looping.")
        with open(output_path, 'wb') as f:
            f.write(data)

if __name__ == "__main__":
    patch_gif_loop('assets/images/congrats.gif', 'assets/images/congrats.gif')
