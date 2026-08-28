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

  - So actually LLMV's own parser uses the previous components to construct names of the form: `S<op0>_<op1>_C<CRn>_C<CRm>_<op2>`
      - it accepts op0 values from 0 - 3 in that generic texual syntax (ref)[https://llvm.org/doxygen/AArch64BaseInfo_8cpp_source.html]
      - and actually on a deeper note the encoding contains only encoded o0 bit and the architeural op0 is formed as `1:o0` thus the architectural MSR (register) system register access can only produce `op0 = 2 `or `op0 = 3`
  - So if we run the follwoing code:
  ```python
  word = 0xD5033FFF

  fields = {
      "op0": (word >> 19) & 0b11,
      "op1": (word >> 16) & 0b111,
      "CRn": (word >> 12) & 0b1111,
      "CRm": (word >> 8) & 0b1111,
      "op2": (word >> 5) & 0b111,
      "Rt": word & 0b11111,
  }

  print(f"word: {word:032b}")

  for name, value in fields.items():
      print(f"{name:4} = {value}")
  ```
  - We should get the follwing output:
    ```python
    word: 11010101000000110011111111111111
    op0  = 0
    op1  = 3
    CRn  = 3
    CRm  = 15
    op2  = 7
    Rt   = 31
    ```
  - Now if we assemble the piece then it becomes: `S0_3_C3_C15_7` which is EXACTLY what aLLVM printed
  - Okay now we can switch our focus to `Rt`. What does that become?
    - So converting it to binary we get `0b11111` and looking again at the table gen inside LLVM we find that this is representitive of the zero register or `xzr` in assembly
  - So now putting this all together the full result of LLVM's complete result is:
    ```python
    msr S0_3_C3_C15_7, xzr
    ```
  - So ARM instructions explicitly maps the following:
  ```python
  o0 = 0 -> op0 = 2
  o0 = 1 -> op0 = 3
  ```
  - This is where our first major clue lies since our canadidate has `op0 = 0` 
  - while LLVM's generic syntax parser permits the following while the MSR (register) form only uses system-register op0 values 2 and 3:
  ```python
  S0_...
  S1_...
  S2_...
  S3_...
  ```
- So now we find ourselves at the question of:
> Why is LLVM interpreting a word with `op0 = 0` as generic `MSR` syntax even though the architectural `MSR (register)` encoding only produces `op0 = 2` or `3`?

## Now onto identifying the instruction calss from the fixed bits
- Okay so first we want to take that word, `0xD5033FFF`, and turn it into something that is a little bit more digestible
  ```python
  word = 0xD5033FFF

  print(f"word:  0x{word:08X}")
  print(f"bits:  {word:032b}")
  print()

  fields = [
      ("31:21", 31, 21),
      ("20:19", 20, 19),
      ("18:16", 18, 16),
      ("15:12", 15, 12),
      ("11:8",  11, 8),
      ("7:5",    7, 5),
      ("4:0",    4, 0),
  ]

  for name, hi, lo in fields:
      width = hi - lo + 1
      value = (word >> lo) & ((1 << width) - 1)
      print(f"{name:5} = {value:0{width}b}")
  ```
Output:
```python
31:21 = 11010101000
20:19 = 00
18:16 = 011
15:12 = 0011
11:8  = 1111
7:5   = 111
4:0   = 11111
```
- Okay so looking at `11010101000` a bunch of AArch64 already live under this prefix 
  - For example we have `SYS` uses the system instrcution form where op0 effectively becomes 01.
  - then you have MSR (register) that uses op0 values 10 or 11
  - all based on this source https://www.scs.stanford.edu/~zyedidia/arm64/sys.html
- Okay no going through this piece by piece:
  - `bits 20:19 = 00` &mdash; pretty esay we now know that our word is not in the architectural MSR (register) encoidng class
    - which is pretty interesting cuz that means LLVM's output as stated preivously would be printing sometihng that looks like an MSR (regisiter), BUT the actual fixed bits do not match architectural MSR (register)
## if not architectural MSR (register) then what?
- okay so now moving our eyes to we can note that this must put us in the same region use by barrier/system-control instructions:
  ```python
  18:16 = 011
  15:12 = 0011
  ```
  - this includes some of the following:
  ```python
  CLREX
  DSB
  DMB
  ISB
  SB
  ```
- Okay now let's compare our candidate with `SB`
  - just for note `SB` is the AArch64 Speculation Barrier instruction
  - Another note is that Arm specifces `SB` as require `FEAT_SB` and its `CRm` fielod is fixed to zero.
    - This would switch our `11:8  = 1111` to `11:8  = 0000`
    - Now everything matches **except** `CRm`
  - So now if we look at this `SB` vs our candidate we find the following:
    - `SB: 0xD50330FF` &mdash; `D503 30 FF`
    - `Candidate: 0xD5033FFF` &mdash; `D503 3F FF`
    - Okay so note that the `0` becoming `F` is basically `CRm` going from `0000` to `1111`
  - This is SO trouble some now cuz it changes our Hypothesis AGAIN
- This is our current state:
  - not architectural MSR(register)
  - resembles barrier/system encoding region
  - same structure as SB except CRm is wrong
  - LLVM nevertheless prints generic MSR syntax
  - Capstone rejects it
- NOW... we are at the point where 
> Should LLVM's instruction decoder have reached the `MSR` printer for this word in the first place?