# Question
```
Can the same 32-bit AArch64 encoding be interpreted differently by current disassemblers, and if it can be than does the difference matter when reverse engineering a real function?
```
# Goal
```
Find one AArch64 encoding where multiple decoding tools disagree, verify the encoding manually, determine why the disagreement occurs, and test whether it changes the analysis of a small compiled function.
```

## Notes
- so basically on aarch64 every nomal instducitn is exactly 32 bits 
  - This is due to the following:
    - **Alignment**: helps with alignment for memory addresses because they will always increase by 4 bytes and the process always knows where the next instruction begins
    - **Faster pipelining**: basically CPUs process mutliple instructions at once (these are in steps called a pipeline) meanign fixed sized means they start decoding right away instead of having the extra overhead of figuring out how long the insturction is
    - **Hardware**: mroe complex logic circuit to figure out varible lenght instructions so keeping it fixes ensures a smaller and cooler chip
  - i.e.
    - If giving instruction `0xD65F03C0` the CPU then tires to figure out what instruction the raw bits represent
      - here `0xD65F03C0` would be `ret`
      - Now on a little endian system those 4 bytes would be stored in reverse order: `C0 03 5F D6`
        - nonetheless the instruction is still valid just changes how they are arranged in memory
  - Tools such as IDA, Ghidra, LLVM, or Capstone all have tools that do this decoding, here I looked for a diagreement between such tools
- So continuing with `0xD65F03C0` in little endian the least significant byte is stored first at the lowest mem address
  - This is either the right most byte or in little endian you would have the table below and as you can see it would still be `C0`:

    | Address | Byte |
    | ------- | ---- |
    | 0x1000  | C0   |
    | 0x1001  | 03   |
    | 0x1002  | 5F   |
    | 0x1003  | D6   |
  - So most tools like IDA, a hex editor, or a raw bianry dump might display it as `C0 03 5F D6` this is something that needs to be noted
- okay now I am going to run a program just to ensure that I am corrrect:
```python
word = 0xD65F03C0

print("Instruction word:", hex(word))
print("Little-endian bytes:", word.to_bytes(4, "little").hex(" "))
print("Big-endian bytes:   ", word.to_bytes(4, "big").hex(" "))
```
**OUTPUT:**
```python
Instruction word: 0xd65f03c0
Little-endian bytes: c0 03 5f d6
Big-endian bytes:    d6 5f 03 c0
```

## What silica completes
- my tool [silica](https://github.com/Nathan-Luevano/silica) takes all the possible 32 bit aarch64 encoding and askings mutlitple sources if that encoding is verified
  - the main oracles (which are just sources that gives answer we can compare against) are:
    - Arm XML specification
    - LLVM
    - Capstone
    - Unicorn
- so for each 32 bit word [silica](https://github.com/Nathan-Luevano/silica) records whether or not each oracle considers the encoding valid
- In this case, the most interesting case is a validity disagreement, where one decoder recognizes an instruction while another rejects the same 32 bit value.
- Basically asks each oracle `Can you decode 0x12345678?`
- 