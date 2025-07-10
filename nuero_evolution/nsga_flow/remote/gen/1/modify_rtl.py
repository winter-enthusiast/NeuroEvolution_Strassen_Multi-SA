import numpy as np
import re

class PEArrayModifier:
    def __init__(self, array_4096, verilog_file="./rtl/top.v"):
        self.array = array_4096
        self.file = verilog_file
    
    def modify(self):
        with open(self.file, 'r') as f:
            content = f.read()
        
        for idx in range(4096):
            x, y = idx//64, idx%64
            new_val = self.array[idx]
            pattern = rf'// MODIFY_HERE_{x}__{y}'
            
            for match in re.finditer(pattern, content):
                start = match.end()
                next_line_start = content.find('\n', start) + 1
                if next_line_start == 0: continue
                
                next_line_end = content.find('\n', next_line_start)
                if next_line_end == -1: next_line_end = len(content)
                
                line = content[next_line_start:next_line_end]
                old = re.search(r'approx_\d+', line)
                if old:
                    new_line = line.replace(old.group(), f'approx_{new_val}', 1)
                    print(f"PE_{x}_{y}: {old.group()} -> approx_{new_val}")
                    content = content[:next_line_start] + new_line + content[next_line_end:]
        
        with open(self.file, 'w') as f:
            f.write(content)

if __name__ == "__main__":
    arr = np.loadtxt('array_config_14.dat', dtype=np.int8)
    modifier = PEArrayModifier(arr)
    modifier.modify()