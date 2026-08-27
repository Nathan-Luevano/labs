# Question
> Can the same 32-bit AArch64 encoding be interpreted differently by current disassemblers, and if it can be than does the difference matter when reverse engineering a real function?

# Goal
> Find one AArch64 encoding where multiple decoding tools disagree, verify the encoding manually, determine why the disagreement occurs, and test whether it changes the analysis of a small compiled function.


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

## Disagreement Candidate

- While searching SILICA's disagreement corpus, `0xD5033FFF` appeared as a candidate where LLVM and Capstone disagreed about validity.

-Candidate:

  `0xD5033FFF`

- Little-endian memory bytes:

  `FF 3F 03 D5`

- SILICA recorded:

| Oracle                  | Result  |
| ----------------------- | ------- |
| Arm-derived spec oracle | Valid   |
| LLVM                    | Valid   |
| Capstone 5.0.7          | Invalid |
| Unicorn                 | Invalid |

- This does not yet prove that any decoder is wrong. The Arm-derived SILICA oracle is not equivalent to executing the complete Arm architectural pseudocode, so the encoding still needs to be independently investigated.

### Independent reproduction
- The SILICA environment uses:
  * Capstone 5.0.7
  * LLVM 22.1.8
- Passing the raw bytes directly to LLVM:
```bash
printf '0xff 0x3f 0x03 0xd5\n' | \
llvm-mc --triple=aarch64 --disassemble
```
- produced:
  ```asm
  msr S0_3_C3_C15_7, xzr
  ```
- Passing the same four bytes to Capstone 5.0.7 produced no decoded instruction.
- This independently reproduced the disagreement reported by SILICA.

### LLVM round-trip test
- Next, LLVM's decoded instruction was passed back into the LLVM assembler:
  ```bash
  printf 'msr S0_3_C3_C15_7, xzr\n' | \
  llvm-mc --triple=aarch64 --show-encoding
  ```
- LLVM produced:
  ```asm
  msr S0_3_C3_C15_7, xzr
  // encoding: [0xff,0x3f,0x03,0xd5]
  ```
- The result therefore round-trips exactly:
  ```
  FF 3F 03 D5
        ↓
  LLVM disassembler
        ↓
  msr S0_3_C3_C15_7, xzr
        ↓
  LLVM assembler
        ↓
  FF 3F 03 D5
  ```
- This shows that LLVM's interpretation is intentional and internally consistent. It does not yet prove that the encoding represents an architecturally valid system-register access.

### What `S0_3_C3_C15_7` means
- LLVM is using the generic AArch64 system-register naming syntax:
  ```
  S<op0>_<op1>_C<CRn>_C<CRm>_<op2>
  ```
- For this encoding LLVM prints:
  ```
  op0 = 0
  op1 = 3
  CRn = 3
  CRm = 15
  op2 = 7
  Rt = XZR
  ```
- giving:
  ```asm
  msr S0_3_C3_C15_7, xzr
  ```
- `xzr` is the zero register, so LLVM is representing the instruction as a write of zero to the generically identified system-register encoding.
- An important question remains: the documented architectural `MSR (register)` form normally uses system-register `op0` values 2 or 3. Our generic LLVM representation contains `op0 = 0`.
- Therefore, the current evidence does **not** justify saying:
> "Capstone fails to decode a valid MSR instruction."
- Instead, the interesting question is why LLVM deliberately decodes and round-trips this encoding while Capstone rejects it.

## Question Change
- The lab originally started with a broad question:
> Why do AArch64 decoders sometimes disagree about the same 32-bit encoding?
- After identifying `0xD5033FFF`, the question can now be narrowed to:
> Why does LLVM decode and round-trip `0xD5033FFF` as `msr S0_3_C3_C15_7, xzr` while Capstone rejects the same encoding, and what happens when the encoding appears inside a real AArch64 function?
- The next goal is to determine whether this difference comes from:
  * LLVM intentionally accepting generic or reserved system-register encodings
  * Capstone enforcing stricter architectural validity
  * a version-specific decoder difference
  * a limitation in SILICA's specification oracle
  * another architectural rule that has not yet been accounted for
- After establishing the architectural reason, the encoding can be embedded inside a small AArch64 function and analyzed with current reverse-engineering tools to determine whether the decoder disagreement has any practical effect on disassembly, function recovery, or decompilation.
## Decoding the LLVM string manually
- Okay so we start with `0xD5033FFF`
  - in binary its `11010101000000110011111111111111`
  - via the [LLVM Project](https://github.com/llvm/llvm-project) we know that the important fields are:
  bits 20:19  -> op0
  bits 18:16  -> op1
  bits 15:12  -> CRn
  bits 11:8   -> CRm
  bits 7:5    -> op2
  bits 4:0    -> Rt

  - So actually LLMV's own parser uses the previous components to construct names of the form: