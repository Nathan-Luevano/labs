
repro-clang:     file format elf64-x86-64


Disassembly of section .init:

0000000000001000 <_init>:
    1000:	f3 0f 1e fa          	endbr64
    1004:	48 83 ec 08          	sub    rsp,0x8
    1008:	48 8b 05 c1 2f 00 00 	mov    rax,QWORD PTR [rip+0x2fc1]        # 3fd0 <__gmon_start__@Base>
    100f:	48 85 c0             	test   rax,rax
    1012:	74 02                	je     1016 <_init+0x16>
    1014:	ff d0                	call   rax
    1016:	48 83 c4 08          	add    rsp,0x8
    101a:	c3                   	ret

Disassembly of section .plt:

0000000000001020 <printf@plt-0x10>:
    1020:	ff 35 ca 2f 00 00    	push   QWORD PTR [rip+0x2fca]        # 3ff0 <_GLOBAL_OFFSET_TABLE_+0x8>
    1026:	ff 25 cc 2f 00 00    	jmp    QWORD PTR [rip+0x2fcc]        # 3ff8 <_GLOBAL_OFFSET_TABLE_+0x10>
    102c:	0f 1f 40 00          	nop    DWORD PTR [rax+0x0]

0000000000001030 <printf@plt>:
    1030:	ff 25 ca 2f 00 00    	jmp    QWORD PTR [rip+0x2fca]        # 4000 <printf@GLIBC_2.2.5>
    1036:	68 00 00 00 00       	push   0x0
    103b:	e9 e0 ff ff ff       	jmp    1020 <_init+0x20>

0000000000001040 <memcpy@plt>:
    1040:	ff 25 c2 2f 00 00    	jmp    QWORD PTR [rip+0x2fc2]        # 4008 <memcpy@GLIBC_2.14>
    1046:	68 01 00 00 00       	push   0x1
    104b:	e9 d0 ff ff ff       	jmp    1020 <_init+0x20>

Disassembly of section .plt.got:

0000000000001050 <__cxa_finalize@plt>:
    1050:	ff 25 8a 2f 00 00    	jmp    QWORD PTR [rip+0x2f8a]        # 3fe0 <__cxa_finalize@GLIBC_2.2.5>
    1056:	66 90                	xchg   ax,ax

Disassembly of section .text:

0000000000001060 <_start>:
    1060:	f3 0f 1e fa          	endbr64
    1064:	31 ed                	xor    ebp,ebp
    1066:	49 89 d1             	mov    r9,rdx
    1069:	5e                   	pop    rsi
    106a:	48 89 e2             	mov    rdx,rsp
    106d:	48 83 e4 f0          	and    rsp,0xfffffffffffffff0
    1071:	50                   	push   rax
    1072:	54                   	push   rsp
    1073:	45 31 c0             	xor    r8d,r8d
    1076:	31 c9                	xor    ecx,ecx
    1078:	48 8d 3d d1 00 00 00 	lea    rdi,[rip+0xd1]        # 1150 <main>
    107f:	ff 15 3b 2f 00 00    	call   QWORD PTR [rip+0x2f3b]        # 3fc0 <__libc_start_main@GLIBC_2.34>
    1085:	f4                   	hlt
    1086:	66 2e 0f 1f 84 00 00 	cs nop WORD PTR [rax+rax*1+0x0]
    108d:	00 00 00 

0000000000001090 <deregister_tm_clones>:
    1090:	48 8d 3d 89 2f 00 00 	lea    rdi,[rip+0x2f89]        # 4020 <__TMC_END__>
    1097:	48 8d 05 82 2f 00 00 	lea    rax,[rip+0x2f82]        # 4020 <__TMC_END__>
    109e:	48 39 f8             	cmp    rax,rdi
    10a1:	74 15                	je     10b8 <deregister_tm_clones+0x28>
    10a3:	48 8b 05 1e 2f 00 00 	mov    rax,QWORD PTR [rip+0x2f1e]        # 3fc8 <_ITM_deregisterTMCloneTable@Base>
    10aa:	48 85 c0             	test   rax,rax
    10ad:	74 09                	je     10b8 <deregister_tm_clones+0x28>
    10af:	ff e0                	jmp    rax
    10b1:	0f 1f 80 00 00 00 00 	nop    DWORD PTR [rax+0x0]
    10b8:	c3                   	ret
    10b9:	0f 1f 80 00 00 00 00 	nop    DWORD PTR [rax+0x0]

00000000000010c0 <register_tm_clones>:
    10c0:	48 8d 3d 59 2f 00 00 	lea    rdi,[rip+0x2f59]        # 4020 <__TMC_END__>
    10c7:	48 8d 35 52 2f 00 00 	lea    rsi,[rip+0x2f52]        # 4020 <__TMC_END__>
    10ce:	48 29 fe             	sub    rsi,rdi
    10d1:	48 89 f0             	mov    rax,rsi
    10d4:	48 c1 ee 3f          	shr    rsi,0x3f
    10d8:	48 c1 f8 03          	sar    rax,0x3
    10dc:	48 01 c6             	add    rsi,rax
    10df:	48 d1 fe             	sar    rsi,1
    10e2:	74 14                	je     10f8 <register_tm_clones+0x38>
    10e4:	48 8b 05 ed 2e 00 00 	mov    rax,QWORD PTR [rip+0x2eed]        # 3fd8 <_ITM_registerTMCloneTable@Base>
    10eb:	48 85 c0             	test   rax,rax
    10ee:	74 08                	je     10f8 <register_tm_clones+0x38>
    10f0:	ff e0                	jmp    rax
    10f2:	66 0f 1f 44 00 00    	nop    WORD PTR [rax+rax*1+0x0]
    10f8:	c3                   	ret
    10f9:	0f 1f 80 00 00 00 00 	nop    DWORD PTR [rax+0x0]

0000000000001100 <__do_global_dtors_aux>:
    1100:	f3 0f 1e fa          	endbr64
    1104:	80 3d 15 2f 00 00 00 	cmp    BYTE PTR [rip+0x2f15],0x0        # 4020 <__TMC_END__>
    110b:	75 2b                	jne    1138 <__do_global_dtors_aux+0x38>
    110d:	55                   	push   rbp
    110e:	48 83 3d ca 2e 00 00 	cmp    QWORD PTR [rip+0x2eca],0x0        # 3fe0 <__cxa_finalize@GLIBC_2.2.5>
    1115:	00 
    1116:	48 89 e5             	mov    rbp,rsp
    1119:	74 0c                	je     1127 <__do_global_dtors_aux+0x27>
    111b:	48 8b 3d f6 2e 00 00 	mov    rdi,QWORD PTR [rip+0x2ef6]        # 4018 <__dso_handle>
    1122:	e8 29 ff ff ff       	call   1050 <__cxa_finalize@plt>
    1127:	e8 64 ff ff ff       	call   1090 <deregister_tm_clones>
    112c:	c6 05 ed 2e 00 00 01 	mov    BYTE PTR [rip+0x2eed],0x1        # 4020 <__TMC_END__>
    1133:	5d                   	pop    rbp
    1134:	c3                   	ret
    1135:	0f 1f 00             	nop    DWORD PTR [rax]
    1138:	c3                   	ret
    1139:	0f 1f 80 00 00 00 00 	nop    DWORD PTR [rax+0x0]

0000000000001140 <frame_dummy>:
    1140:	f3 0f 1e fa          	endbr64
    1144:	e9 77 ff ff ff       	jmp    10c0 <register_tm_clones>
    1149:	0f 1f 80 00 00 00 00 	nop    DWORD PTR [rax+0x0]

0000000000001150 <main>:
    1150:	55                   	push   rbp
    1151:	48 89 e5             	mov    rbp,rsp
    1154:	48 83 ec 30          	sub    rsp,0x30
    1158:	c7 45 fc 00 00 00 00 	mov    DWORD PTR [rbp-0x4],0x0
    115f:	48 8d 7d d0          	lea    rdi,[rbp-0x30]
    1163:	48 8d 35 a6 0e 00 00 	lea    rsi,[rip+0xea6]        # 2010 <_IO_stdin_used+0x10>
    116a:	ba 21 00 00 00       	mov    edx,0x21
    116f:	e8 cc fe ff ff       	call   1040 <memcpy@plt>
    1174:	48 8d 7d d0          	lea    rdi,[rbp-0x30]
    1178:	be 21 00 00 00       	mov    esi,0x21
    117d:	e8 0e 00 00 00       	call   1190 <parse_record>
    1182:	48 83 c4 30          	add    rsp,0x30
    1186:	5d                   	pop    rbp
    1187:	c3                   	ret
    1188:	0f 1f 84 00 00 00 00 	nop    DWORD PTR [rax+rax*1+0x0]
    118f:	00 

0000000000001190 <parse_record>:
    1190:	55                   	push   rbp
    1191:	48 89 e5             	mov    rbp,rsp
    1194:	48 83 ec 40          	sub    rsp,0x40
    1198:	48 89 7d f0          	mov    QWORD PTR [rbp-0x10],rdi
    119c:	48 89 75 e8          	mov    QWORD PTR [rbp-0x18],rsi
    11a0:	48 83 7d e8 02       	cmp    QWORD PTR [rbp-0x18],0x2
    11a5:	0f 83 0c 00 00 00    	jae    11b7 <parse_record+0x27>
    11ab:	c7 45 fc ff ff ff ff 	mov    DWORD PTR [rbp-0x4],0xffffffff
    11b2:	e9 3d 00 00 00       	jmp    11f4 <parse_record+0x64>
    11b7:	48 8b 45 f0          	mov    rax,QWORD PTR [rbp-0x10]
    11bb:	8a 00                	mov    al,BYTE PTR [rax]
    11bd:	88 45 cf             	mov    BYTE PTR [rbp-0x31],al
    11c0:	48 8d 7d d0          	lea    rdi,[rbp-0x30]
    11c4:	48 8b 75 f0          	mov    rsi,QWORD PTR [rbp-0x10]
    11c8:	48 83 c6 01          	add    rsi,0x1
    11cc:	0f b6 45 cf          	movzx  eax,BYTE PTR [rbp-0x31]
    11d0:	89 c2                	mov    edx,eax
    11d2:	e8 69 fe ff ff       	call   1040 <memcpy@plt>
    11d7:	c6 45 df 00          	mov    BYTE PTR [rbp-0x21],0x0
    11db:	48 8d 75 d0          	lea    rsi,[rbp-0x30]
    11df:	48 8d 3d 4b 0e 00 00 	lea    rdi,[rip+0xe4b]        # 2031 <_IO_stdin_used+0x31>
    11e6:	b0 00                	mov    al,0x0
    11e8:	e8 43 fe ff ff       	call   1030 <printf@plt>
    11ed:	c7 45 fc 00 00 00 00 	mov    DWORD PTR [rbp-0x4],0x0
    11f4:	8b 45 fc             	mov    eax,DWORD PTR [rbp-0x4]
    11f7:	48 83 c4 40          	add    rsp,0x40
    11fb:	5d                   	pop    rbp
    11fc:	c3                   	ret

Disassembly of section .fini:

0000000000001200 <_fini>:
    1200:	f3 0f 1e fa          	endbr64
    1204:	48 83 ec 08          	sub    rsp,0x8
    1208:	48 83 c4 08          	add    rsp,0x8
    120c:	c3                   	ret
