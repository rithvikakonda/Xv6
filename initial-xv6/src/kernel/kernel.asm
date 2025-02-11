
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000b117          	auipc	sp,0xb
    80000004:	44013103          	ld	sp,1088(sp) # 8000b440 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	1761                	addi	a4,a4,-8 # 200bff8 <_entry-0x7dff4008>
    8000003a:	6318                	ld	a4,0(a4)
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	0000b717          	auipc	a4,0xb
    80000054:	45070713          	addi	a4,a4,1104 # 8000b4a0 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	6be78793          	addi	a5,a5,1726 # 80006720 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd66af>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e2678793          	addi	a5,a5,-474 # 80000ed2 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	f84a                	sd	s2,48(sp)
    80000108:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    8000010a:	04c05663          	blez	a2,80000156 <consolewrite+0x56>
    8000010e:	fc26                	sd	s1,56(sp)
    80000110:	f44e                	sd	s3,40(sp)
    80000112:	f052                	sd	s4,32(sp)
    80000114:	ec56                	sd	s5,24(sp)
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	8de080e7          	jalr	-1826(ra) # 80002a08 <either_copyin>
    80000132:	03550463          	beq	a0,s5,8000015a <consolewrite+0x5a>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	7e4080e7          	jalr	2020(ra) # 8000091e <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    8000014c:	74e2                	ld	s1,56(sp)
    8000014e:	79a2                	ld	s3,40(sp)
    80000150:	7a02                	ld	s4,32(sp)
    80000152:	6ae2                	ld	s5,24(sp)
    80000154:	a039                	j	80000162 <consolewrite+0x62>
    80000156:	4901                	li	s2,0
    80000158:	a029                	j	80000162 <consolewrite+0x62>
    8000015a:	74e2                	ld	s1,56(sp)
    8000015c:	79a2                	ld	s3,40(sp)
    8000015e:	7a02                	ld	s4,32(sp)
    80000160:	6ae2                	ld	s5,24(sp)
  }

  return i;
}
    80000162:	854a                	mv	a0,s2
    80000164:	60a6                	ld	ra,72(sp)
    80000166:	6406                	ld	s0,64(sp)
    80000168:	7942                	ld	s2,48(sp)
    8000016a:	6161                	addi	sp,sp,80
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00013517          	auipc	a0,0x13
    80000190:	45450513          	addi	a0,a0,1108 # 800135e0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	aa4080e7          	jalr	-1372(ra) # 80000c38 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00013497          	auipc	s1,0x13
    800001a0:	44448493          	addi	s1,s1,1092 # 800135e0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	00013917          	auipc	s2,0x13
    800001a8:	4d490913          	addi	s2,s2,1236 # 80013678 <cons+0x98>
  while(n > 0){
    800001ac:	0d305763          	blez	s3,8000027a <consoleread+0x10c>
    while(cons.r == cons.w){
    800001b0:	0984a783          	lw	a5,152(s1)
    800001b4:	09c4a703          	lw	a4,156(s1)
    800001b8:	0af71c63          	bne	a4,a5,80000270 <consoleread+0x102>
      if(killed(myproc())){
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	b78080e7          	jalr	-1160(ra) # 80001d34 <myproc>
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	676080e7          	jalr	1654(ra) # 8000283a <killed>
    800001cc:	e52d                	bnez	a0,80000236 <consoleread+0xc8>
      sleep(&cons.r, &cons.lock);
    800001ce:	85a6                	mv	a1,s1
    800001d0:	854a                	mv	a0,s2
    800001d2:	00002097          	auipc	ra,0x2
    800001d6:	384080e7          	jalr	900(ra) # 80002556 <sleep>
    while(cons.r == cons.w){
    800001da:	0984a783          	lw	a5,152(s1)
    800001de:	09c4a703          	lw	a4,156(s1)
    800001e2:	fcf70de3          	beq	a4,a5,800001bc <consoleread+0x4e>
    800001e6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001e8:	00013717          	auipc	a4,0x13
    800001ec:	3f870713          	addi	a4,a4,1016 # 800135e0 <cons>
    800001f0:	0017869b          	addiw	a3,a5,1
    800001f4:	08d72c23          	sw	a3,152(a4)
    800001f8:	07f7f693          	andi	a3,a5,127
    800001fc:	9736                	add	a4,a4,a3
    800001fe:	01874703          	lbu	a4,24(a4)
    80000202:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    80000206:	4691                	li	a3,4
    80000208:	04db8a63          	beq	s7,a3,8000025c <consoleread+0xee>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    8000020c:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	faf40613          	addi	a2,s0,-81
    80000216:	85d2                	mv	a1,s4
    80000218:	8556                	mv	a0,s5
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	798080e7          	jalr	1944(ra) # 800029b2 <either_copyout>
    80000222:	57fd                	li	a5,-1
    80000224:	04f50a63          	beq	a0,a5,80000278 <consoleread+0x10a>
      break;

    dst++;
    80000228:	0a05                	addi	s4,s4,1
    --n;
    8000022a:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    8000022c:	47a9                	li	a5,10
    8000022e:	06fb8163          	beq	s7,a5,80000290 <consoleread+0x122>
    80000232:	6be2                	ld	s7,24(sp)
    80000234:	bfa5                	j	800001ac <consoleread+0x3e>
        release(&cons.lock);
    80000236:	00013517          	auipc	a0,0x13
    8000023a:	3aa50513          	addi	a0,a0,938 # 800135e0 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	aae080e7          	jalr	-1362(ra) # 80000cec <release>
        return -1;
    80000246:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000248:	60e6                	ld	ra,88(sp)
    8000024a:	6446                	ld	s0,80(sp)
    8000024c:	64a6                	ld	s1,72(sp)
    8000024e:	6906                	ld	s2,64(sp)
    80000250:	79e2                	ld	s3,56(sp)
    80000252:	7a42                	ld	s4,48(sp)
    80000254:	7aa2                	ld	s5,40(sp)
    80000256:	7b02                	ld	s6,32(sp)
    80000258:	6125                	addi	sp,sp,96
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	0009871b          	sext.w	a4,s3
    80000260:	01677a63          	bgeu	a4,s6,80000274 <consoleread+0x106>
        cons.r--;
    80000264:	00013717          	auipc	a4,0x13
    80000268:	40f72a23          	sw	a5,1044(a4) # 80013678 <cons+0x98>
    8000026c:	6be2                	ld	s7,24(sp)
    8000026e:	a031                	j	8000027a <consoleread+0x10c>
    80000270:	ec5e                	sd	s7,24(sp)
    80000272:	bf9d                	j	800001e8 <consoleread+0x7a>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	a011                	j	8000027a <consoleread+0x10c>
    80000278:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    8000027a:	00013517          	auipc	a0,0x13
    8000027e:	36650513          	addi	a0,a0,870 # 800135e0 <cons>
    80000282:	00001097          	auipc	ra,0x1
    80000286:	a6a080e7          	jalr	-1430(ra) # 80000cec <release>
  return target - n;
    8000028a:	413b053b          	subw	a0,s6,s3
    8000028e:	bf6d                	j	80000248 <consoleread+0xda>
    80000290:	6be2                	ld	s7,24(sp)
    80000292:	b7e5                	j	8000027a <consoleread+0x10c>

0000000080000294 <consputc>:
{
    80000294:	1141                	addi	sp,sp,-16
    80000296:	e406                	sd	ra,8(sp)
    80000298:	e022                	sd	s0,0(sp)
    8000029a:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000029c:	10000793          	li	a5,256
    800002a0:	00f50a63          	beq	a0,a5,800002b4 <consputc+0x20>
    uartputc_sync(c);
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	59c080e7          	jalr	1436(ra) # 80000840 <uartputc_sync>
}
    800002ac:	60a2                	ld	ra,8(sp)
    800002ae:	6402                	ld	s0,0(sp)
    800002b0:	0141                	addi	sp,sp,16
    800002b2:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002b4:	4521                	li	a0,8
    800002b6:	00000097          	auipc	ra,0x0
    800002ba:	58a080e7          	jalr	1418(ra) # 80000840 <uartputc_sync>
    800002be:	02000513          	li	a0,32
    800002c2:	00000097          	auipc	ra,0x0
    800002c6:	57e080e7          	jalr	1406(ra) # 80000840 <uartputc_sync>
    800002ca:	4521                	li	a0,8
    800002cc:	00000097          	auipc	ra,0x0
    800002d0:	574080e7          	jalr	1396(ra) # 80000840 <uartputc_sync>
    800002d4:	bfe1                	j	800002ac <consputc+0x18>

00000000800002d6 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d6:	1101                	addi	sp,sp,-32
    800002d8:	ec06                	sd	ra,24(sp)
    800002da:	e822                	sd	s0,16(sp)
    800002dc:	e426                	sd	s1,8(sp)
    800002de:	1000                	addi	s0,sp,32
    800002e0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002e2:	00013517          	auipc	a0,0x13
    800002e6:	2fe50513          	addi	a0,a0,766 # 800135e0 <cons>
    800002ea:	00001097          	auipc	ra,0x1
    800002ee:	94e080e7          	jalr	-1714(ra) # 80000c38 <acquire>

  switch(c){
    800002f2:	47d5                	li	a5,21
    800002f4:	0af48563          	beq	s1,a5,8000039e <consoleintr+0xc8>
    800002f8:	0297c963          	blt	a5,s1,8000032a <consoleintr+0x54>
    800002fc:	47a1                	li	a5,8
    800002fe:	0ef48c63          	beq	s1,a5,800003f6 <consoleintr+0x120>
    80000302:	47c1                	li	a5,16
    80000304:	10f49f63          	bne	s1,a5,80000422 <consoleintr+0x14c>
  case C('P'):  // Print process list.
    procdump();
    80000308:	00002097          	auipc	ra,0x2
    8000030c:	756080e7          	jalr	1878(ra) # 80002a5e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000310:	00013517          	auipc	a0,0x13
    80000314:	2d050513          	addi	a0,a0,720 # 800135e0 <cons>
    80000318:	00001097          	auipc	ra,0x1
    8000031c:	9d4080e7          	jalr	-1580(ra) # 80000cec <release>
}
    80000320:	60e2                	ld	ra,24(sp)
    80000322:	6442                	ld	s0,16(sp)
    80000324:	64a2                	ld	s1,8(sp)
    80000326:	6105                	addi	sp,sp,32
    80000328:	8082                	ret
  switch(c){
    8000032a:	07f00793          	li	a5,127
    8000032e:	0cf48463          	beq	s1,a5,800003f6 <consoleintr+0x120>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000332:	00013717          	auipc	a4,0x13
    80000336:	2ae70713          	addi	a4,a4,686 # 800135e0 <cons>
    8000033a:	0a072783          	lw	a5,160(a4)
    8000033e:	09872703          	lw	a4,152(a4)
    80000342:	9f99                	subw	a5,a5,a4
    80000344:	07f00713          	li	a4,127
    80000348:	fcf764e3          	bltu	a4,a5,80000310 <consoleintr+0x3a>
      c = (c == '\r') ? '\n' : c;
    8000034c:	47b5                	li	a5,13
    8000034e:	0cf48d63          	beq	s1,a5,80000428 <consoleintr+0x152>
      consputc(c);
    80000352:	8526                	mv	a0,s1
    80000354:	00000097          	auipc	ra,0x0
    80000358:	f40080e7          	jalr	-192(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000035c:	00013797          	auipc	a5,0x13
    80000360:	28478793          	addi	a5,a5,644 # 800135e0 <cons>
    80000364:	0a07a683          	lw	a3,160(a5)
    80000368:	0016871b          	addiw	a4,a3,1
    8000036c:	0007061b          	sext.w	a2,a4
    80000370:	0ae7a023          	sw	a4,160(a5)
    80000374:	07f6f693          	andi	a3,a3,127
    80000378:	97b6                	add	a5,a5,a3
    8000037a:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000037e:	47a9                	li	a5,10
    80000380:	0cf48b63          	beq	s1,a5,80000456 <consoleintr+0x180>
    80000384:	4791                	li	a5,4
    80000386:	0cf48863          	beq	s1,a5,80000456 <consoleintr+0x180>
    8000038a:	00013797          	auipc	a5,0x13
    8000038e:	2ee7a783          	lw	a5,750(a5) # 80013678 <cons+0x98>
    80000392:	9f1d                	subw	a4,a4,a5
    80000394:	08000793          	li	a5,128
    80000398:	f6f71ce3          	bne	a4,a5,80000310 <consoleintr+0x3a>
    8000039c:	a86d                	j	80000456 <consoleintr+0x180>
    8000039e:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    800003a0:	00013717          	auipc	a4,0x13
    800003a4:	24070713          	addi	a4,a4,576 # 800135e0 <cons>
    800003a8:	0a072783          	lw	a5,160(a4)
    800003ac:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003b0:	00013497          	auipc	s1,0x13
    800003b4:	23048493          	addi	s1,s1,560 # 800135e0 <cons>
    while(cons.e != cons.w &&
    800003b8:	4929                	li	s2,10
    800003ba:	02f70a63          	beq	a4,a5,800003ee <consoleintr+0x118>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003be:	37fd                	addiw	a5,a5,-1
    800003c0:	07f7f713          	andi	a4,a5,127
    800003c4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c6:	01874703          	lbu	a4,24(a4)
    800003ca:	03270463          	beq	a4,s2,800003f2 <consoleintr+0x11c>
      cons.e--;
    800003ce:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003d2:	10000513          	li	a0,256
    800003d6:	00000097          	auipc	ra,0x0
    800003da:	ebe080e7          	jalr	-322(ra) # 80000294 <consputc>
    while(cons.e != cons.w &&
    800003de:	0a04a783          	lw	a5,160(s1)
    800003e2:	09c4a703          	lw	a4,156(s1)
    800003e6:	fcf71ce3          	bne	a4,a5,800003be <consoleintr+0xe8>
    800003ea:	6902                	ld	s2,0(sp)
    800003ec:	b715                	j	80000310 <consoleintr+0x3a>
    800003ee:	6902                	ld	s2,0(sp)
    800003f0:	b705                	j	80000310 <consoleintr+0x3a>
    800003f2:	6902                	ld	s2,0(sp)
    800003f4:	bf31                	j	80000310 <consoleintr+0x3a>
    if(cons.e != cons.w){
    800003f6:	00013717          	auipc	a4,0x13
    800003fa:	1ea70713          	addi	a4,a4,490 # 800135e0 <cons>
    800003fe:	0a072783          	lw	a5,160(a4)
    80000402:	09c72703          	lw	a4,156(a4)
    80000406:	f0f705e3          	beq	a4,a5,80000310 <consoleintr+0x3a>
      cons.e--;
    8000040a:	37fd                	addiw	a5,a5,-1
    8000040c:	00013717          	auipc	a4,0x13
    80000410:	26f72a23          	sw	a5,628(a4) # 80013680 <cons+0xa0>
      consputc(BACKSPACE);
    80000414:	10000513          	li	a0,256
    80000418:	00000097          	auipc	ra,0x0
    8000041c:	e7c080e7          	jalr	-388(ra) # 80000294 <consputc>
    80000420:	bdc5                	j	80000310 <consoleintr+0x3a>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000422:	ee0487e3          	beqz	s1,80000310 <consoleintr+0x3a>
    80000426:	b731                	j	80000332 <consoleintr+0x5c>
      consputc(c);
    80000428:	4529                	li	a0,10
    8000042a:	00000097          	auipc	ra,0x0
    8000042e:	e6a080e7          	jalr	-406(ra) # 80000294 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000432:	00013797          	auipc	a5,0x13
    80000436:	1ae78793          	addi	a5,a5,430 # 800135e0 <cons>
    8000043a:	0a07a703          	lw	a4,160(a5)
    8000043e:	0017069b          	addiw	a3,a4,1
    80000442:	0006861b          	sext.w	a2,a3
    80000446:	0ad7a023          	sw	a3,160(a5)
    8000044a:	07f77713          	andi	a4,a4,127
    8000044e:	97ba                	add	a5,a5,a4
    80000450:	4729                	li	a4,10
    80000452:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000456:	00013797          	auipc	a5,0x13
    8000045a:	22c7a323          	sw	a2,550(a5) # 8001367c <cons+0x9c>
        wakeup(&cons.r);
    8000045e:	00013517          	auipc	a0,0x13
    80000462:	21a50513          	addi	a0,a0,538 # 80013678 <cons+0x98>
    80000466:	00002097          	auipc	ra,0x2
    8000046a:	16e080e7          	jalr	366(ra) # 800025d4 <wakeup>
    8000046e:	b54d                	j	80000310 <consoleintr+0x3a>

0000000080000470 <consoleinit>:

void
consoleinit(void)
{
    80000470:	1141                	addi	sp,sp,-16
    80000472:	e406                	sd	ra,8(sp)
    80000474:	e022                	sd	s0,0(sp)
    80000476:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000478:	00008597          	auipc	a1,0x8
    8000047c:	b8858593          	addi	a1,a1,-1144 # 80008000 <etext>
    80000480:	00013517          	auipc	a0,0x13
    80000484:	16050513          	addi	a0,a0,352 # 800135e0 <cons>
    80000488:	00000097          	auipc	ra,0x0
    8000048c:	720080e7          	jalr	1824(ra) # 80000ba8 <initlock>

  uartinit();
    80000490:	00000097          	auipc	ra,0x0
    80000494:	354080e7          	jalr	852(ra) # 800007e4 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000498:	00027797          	auipc	a5,0x27
    8000049c:	b2078793          	addi	a5,a5,-1248 # 80026fb8 <devsw>
    800004a0:	00000717          	auipc	a4,0x0
    800004a4:	cce70713          	addi	a4,a4,-818 # 8000016e <consoleread>
    800004a8:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    800004aa:	00000717          	auipc	a4,0x0
    800004ae:	c5670713          	addi	a4,a4,-938 # 80000100 <consolewrite>
    800004b2:	ef98                	sd	a4,24(a5)
}
    800004b4:	60a2                	ld	ra,8(sp)
    800004b6:	6402                	ld	s0,0(sp)
    800004b8:	0141                	addi	sp,sp,16
    800004ba:	8082                	ret

00000000800004bc <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004bc:	7179                	addi	sp,sp,-48
    800004be:	f406                	sd	ra,40(sp)
    800004c0:	f022                	sd	s0,32(sp)
    800004c2:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004c4:	c219                	beqz	a2,800004ca <printint+0xe>
    800004c6:	08054963          	bltz	a0,80000558 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ca:	2501                	sext.w	a0,a0
    800004cc:	4881                	li	a7,0
    800004ce:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004d2:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004d4:	2581                	sext.w	a1,a1
    800004d6:	00008617          	auipc	a2,0x8
    800004da:	28a60613          	addi	a2,a2,650 # 80008760 <digits>
    800004de:	883a                	mv	a6,a4
    800004e0:	2705                	addiw	a4,a4,1
    800004e2:	02b577bb          	remuw	a5,a0,a1
    800004e6:	1782                	slli	a5,a5,0x20
    800004e8:	9381                	srli	a5,a5,0x20
    800004ea:	97b2                	add	a5,a5,a2
    800004ec:	0007c783          	lbu	a5,0(a5)
    800004f0:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004f4:	0005079b          	sext.w	a5,a0
    800004f8:	02b5553b          	divuw	a0,a0,a1
    800004fc:	0685                	addi	a3,a3,1
    800004fe:	feb7f0e3          	bgeu	a5,a1,800004de <printint+0x22>

  if(sign)
    80000502:	00088c63          	beqz	a7,8000051a <printint+0x5e>
    buf[i++] = '-';
    80000506:	fe070793          	addi	a5,a4,-32
    8000050a:	00878733          	add	a4,a5,s0
    8000050e:	02d00793          	li	a5,45
    80000512:	fef70823          	sb	a5,-16(a4)
    80000516:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000051a:	02e05b63          	blez	a4,80000550 <printint+0x94>
    8000051e:	ec26                	sd	s1,24(sp)
    80000520:	e84a                	sd	s2,16(sp)
    80000522:	fd040793          	addi	a5,s0,-48
    80000526:	00e784b3          	add	s1,a5,a4
    8000052a:	fff78913          	addi	s2,a5,-1
    8000052e:	993a                	add	s2,s2,a4
    80000530:	377d                	addiw	a4,a4,-1
    80000532:	1702                	slli	a4,a4,0x20
    80000534:	9301                	srli	a4,a4,0x20
    80000536:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000053a:	fff4c503          	lbu	a0,-1(s1)
    8000053e:	00000097          	auipc	ra,0x0
    80000542:	d56080e7          	jalr	-682(ra) # 80000294 <consputc>
  while(--i >= 0)
    80000546:	14fd                	addi	s1,s1,-1
    80000548:	ff2499e3          	bne	s1,s2,8000053a <printint+0x7e>
    8000054c:	64e2                	ld	s1,24(sp)
    8000054e:	6942                	ld	s2,16(sp)
}
    80000550:	70a2                	ld	ra,40(sp)
    80000552:	7402                	ld	s0,32(sp)
    80000554:	6145                	addi	sp,sp,48
    80000556:	8082                	ret
    x = -xx;
    80000558:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000055c:	4885                	li	a7,1
    x = -xx;
    8000055e:	bf85                	j	800004ce <printint+0x12>

0000000080000560 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000560:	1101                	addi	sp,sp,-32
    80000562:	ec06                	sd	ra,24(sp)
    80000564:	e822                	sd	s0,16(sp)
    80000566:	e426                	sd	s1,8(sp)
    80000568:	1000                	addi	s0,sp,32
    8000056a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000056c:	00013797          	auipc	a5,0x13
    80000570:	1207aa23          	sw	zero,308(a5) # 800136a0 <pr+0x18>
  printf("panic: ");
    80000574:	00008517          	auipc	a0,0x8
    80000578:	a9450513          	addi	a0,a0,-1388 # 80008008 <etext+0x8>
    8000057c:	00000097          	auipc	ra,0x0
    80000580:	02e080e7          	jalr	46(ra) # 800005aa <printf>
  printf(s);
    80000584:	8526                	mv	a0,s1
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	024080e7          	jalr	36(ra) # 800005aa <printf>
  printf("\n");
    8000058e:	00008517          	auipc	a0,0x8
    80000592:	a8250513          	addi	a0,a0,-1406 # 80008010 <etext+0x10>
    80000596:	00000097          	auipc	ra,0x0
    8000059a:	014080e7          	jalr	20(ra) # 800005aa <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000059e:	4785                	li	a5,1
    800005a0:	0000b717          	auipc	a4,0xb
    800005a4:	ecf72023          	sw	a5,-320(a4) # 8000b460 <panicked>
  for(;;)
    800005a8:	a001                	j	800005a8 <panic+0x48>

00000000800005aa <printf>:
{
    800005aa:	7131                	addi	sp,sp,-192
    800005ac:	fc86                	sd	ra,120(sp)
    800005ae:	f8a2                	sd	s0,112(sp)
    800005b0:	e8d2                	sd	s4,80(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ca:	00013d17          	auipc	s10,0x13
    800005ce:	0d6d2d03          	lw	s10,214(s10) # 800136a0 <pr+0x18>
  if(locking)
    800005d2:	040d1463          	bnez	s10,8000061a <printf+0x70>
  if (fmt == 0)
    800005d6:	040a0b63          	beqz	s4,8000062c <printf+0x82>
  va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	18050b63          	beqz	a0,8000077c <printf+0x1d2>
    800005ea:	f4a6                	sd	s1,104(sp)
    800005ec:	f0ca                	sd	s2,96(sp)
    800005ee:	ecce                	sd	s3,88(sp)
    800005f0:	e4d6                	sd	s5,72(sp)
    800005f2:	e0da                	sd	s6,64(sp)
    800005f4:	fc5e                	sd	s7,56(sp)
    800005f6:	f862                	sd	s8,48(sp)
    800005f8:	f466                	sd	s9,40(sp)
    800005fa:	ec6e                	sd	s11,24(sp)
    800005fc:	4981                	li	s3,0
    if(c != '%'){
    800005fe:	02500b13          	li	s6,37
    switch(c){
    80000602:	07000b93          	li	s7,112
  consputc('x');
    80000606:	4cc1                	li	s9,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000608:	00008a97          	auipc	s5,0x8
    8000060c:	158a8a93          	addi	s5,s5,344 # 80008760 <digits>
    switch(c){
    80000610:	07300c13          	li	s8,115
    80000614:	06400d93          	li	s11,100
    80000618:	a0b1                	j	80000664 <printf+0xba>
    acquire(&pr.lock);
    8000061a:	00013517          	auipc	a0,0x13
    8000061e:	06e50513          	addi	a0,a0,110 # 80013688 <pr>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	616080e7          	jalr	1558(ra) # 80000c38 <acquire>
    8000062a:	b775                	j	800005d6 <printf+0x2c>
    8000062c:	f4a6                	sd	s1,104(sp)
    8000062e:	f0ca                	sd	s2,96(sp)
    80000630:	ecce                	sd	s3,88(sp)
    80000632:	e4d6                	sd	s5,72(sp)
    80000634:	e0da                	sd	s6,64(sp)
    80000636:	fc5e                	sd	s7,56(sp)
    80000638:	f862                	sd	s8,48(sp)
    8000063a:	f466                	sd	s9,40(sp)
    8000063c:	ec6e                	sd	s11,24(sp)
    panic("null fmt");
    8000063e:	00008517          	auipc	a0,0x8
    80000642:	9e250513          	addi	a0,a0,-1566 # 80008020 <etext+0x20>
    80000646:	00000097          	auipc	ra,0x0
    8000064a:	f1a080e7          	jalr	-230(ra) # 80000560 <panic>
      consputc(c);
    8000064e:	00000097          	auipc	ra,0x0
    80000652:	c46080e7          	jalr	-954(ra) # 80000294 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000656:	2985                	addiw	s3,s3,1
    80000658:	013a07b3          	add	a5,s4,s3
    8000065c:	0007c503          	lbu	a0,0(a5)
    80000660:	10050563          	beqz	a0,8000076a <printf+0x1c0>
    if(c != '%'){
    80000664:	ff6515e3          	bne	a0,s6,8000064e <printf+0xa4>
    c = fmt[++i] & 0xff;
    80000668:	2985                	addiw	s3,s3,1
    8000066a:	013a07b3          	add	a5,s4,s3
    8000066e:	0007c783          	lbu	a5,0(a5)
    80000672:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000676:	10078b63          	beqz	a5,8000078c <printf+0x1e2>
    switch(c){
    8000067a:	05778a63          	beq	a5,s7,800006ce <printf+0x124>
    8000067e:	02fbf663          	bgeu	s7,a5,800006aa <printf+0x100>
    80000682:	09878863          	beq	a5,s8,80000712 <printf+0x168>
    80000686:	07800713          	li	a4,120
    8000068a:	0ce79563          	bne	a5,a4,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 16, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	85e6                	mv	a1,s9
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e1c080e7          	jalr	-484(ra) # 800004bc <printint>
      break;
    800006a8:	b77d                	j	80000656 <printf+0xac>
    switch(c){
    800006aa:	09678f63          	beq	a5,s6,80000748 <printf+0x19e>
    800006ae:	0bb79363          	bne	a5,s11,80000754 <printf+0x1aa>
      printint(va_arg(ap, int), 10, 1);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4605                	li	a2,1
    800006c0:	45a9                	li	a1,10
    800006c2:	4388                	lw	a0,0(a5)
    800006c4:	00000097          	auipc	ra,0x0
    800006c8:	df8080e7          	jalr	-520(ra) # 800004bc <printint>
      break;
    800006cc:	b769                	j	80000656 <printf+0xac>
      printptr(va_arg(ap, uint64));
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006de:	03000513          	li	a0,48
    800006e2:	00000097          	auipc	ra,0x0
    800006e6:	bb2080e7          	jalr	-1102(ra) # 80000294 <consputc>
  consputc('x');
    800006ea:	07800513          	li	a0,120
    800006ee:	00000097          	auipc	ra,0x0
    800006f2:	ba6080e7          	jalr	-1114(ra) # 80000294 <consputc>
    800006f6:	84e6                	mv	s1,s9
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006f8:	03c95793          	srli	a5,s2,0x3c
    800006fc:	97d6                	add	a5,a5,s5
    800006fe:	0007c503          	lbu	a0,0(a5)
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b92080e7          	jalr	-1134(ra) # 80000294 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000070a:	0912                	slli	s2,s2,0x4
    8000070c:	34fd                	addiw	s1,s1,-1
    8000070e:	f4ed                	bnez	s1,800006f8 <printf+0x14e>
    80000710:	b799                	j	80000656 <printf+0xac>
      if((s = va_arg(ap, char*)) == 0)
    80000712:	f8843783          	ld	a5,-120(s0)
    80000716:	00878713          	addi	a4,a5,8
    8000071a:	f8e43423          	sd	a4,-120(s0)
    8000071e:	6384                	ld	s1,0(a5)
    80000720:	cc89                	beqz	s1,8000073a <printf+0x190>
      for(; *s; s++)
    80000722:	0004c503          	lbu	a0,0(s1)
    80000726:	d905                	beqz	a0,80000656 <printf+0xac>
        consputc(*s);
    80000728:	00000097          	auipc	ra,0x0
    8000072c:	b6c080e7          	jalr	-1172(ra) # 80000294 <consputc>
      for(; *s; s++)
    80000730:	0485                	addi	s1,s1,1
    80000732:	0004c503          	lbu	a0,0(s1)
    80000736:	f96d                	bnez	a0,80000728 <printf+0x17e>
    80000738:	bf39                	j	80000656 <printf+0xac>
        s = "(null)";
    8000073a:	00008497          	auipc	s1,0x8
    8000073e:	8de48493          	addi	s1,s1,-1826 # 80008018 <etext+0x18>
      for(; *s; s++)
    80000742:	02800513          	li	a0,40
    80000746:	b7cd                	j	80000728 <printf+0x17e>
      consputc('%');
    80000748:	855a                	mv	a0,s6
    8000074a:	00000097          	auipc	ra,0x0
    8000074e:	b4a080e7          	jalr	-1206(ra) # 80000294 <consputc>
      break;
    80000752:	b711                	j	80000656 <printf+0xac>
      consputc('%');
    80000754:	855a                	mv	a0,s6
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	b3e080e7          	jalr	-1218(ra) # 80000294 <consputc>
      consputc(c);
    8000075e:	8526                	mv	a0,s1
    80000760:	00000097          	auipc	ra,0x0
    80000764:	b34080e7          	jalr	-1228(ra) # 80000294 <consputc>
      break;
    80000768:	b5fd                	j	80000656 <printf+0xac>
    8000076a:	74a6                	ld	s1,104(sp)
    8000076c:	7906                	ld	s2,96(sp)
    8000076e:	69e6                	ld	s3,88(sp)
    80000770:	6aa6                	ld	s5,72(sp)
    80000772:	6b06                	ld	s6,64(sp)
    80000774:	7be2                	ld	s7,56(sp)
    80000776:	7c42                	ld	s8,48(sp)
    80000778:	7ca2                	ld	s9,40(sp)
    8000077a:	6de2                	ld	s11,24(sp)
  if(locking)
    8000077c:	020d1263          	bnez	s10,800007a0 <printf+0x1f6>
}
    80000780:	70e6                	ld	ra,120(sp)
    80000782:	7446                	ld	s0,112(sp)
    80000784:	6a46                	ld	s4,80(sp)
    80000786:	7d02                	ld	s10,32(sp)
    80000788:	6129                	addi	sp,sp,192
    8000078a:	8082                	ret
    8000078c:	74a6                	ld	s1,104(sp)
    8000078e:	7906                	ld	s2,96(sp)
    80000790:	69e6                	ld	s3,88(sp)
    80000792:	6aa6                	ld	s5,72(sp)
    80000794:	6b06                	ld	s6,64(sp)
    80000796:	7be2                	ld	s7,56(sp)
    80000798:	7c42                	ld	s8,48(sp)
    8000079a:	7ca2                	ld	s9,40(sp)
    8000079c:	6de2                	ld	s11,24(sp)
    8000079e:	bff9                	j	8000077c <printf+0x1d2>
    release(&pr.lock);
    800007a0:	00013517          	auipc	a0,0x13
    800007a4:	ee850513          	addi	a0,a0,-280 # 80013688 <pr>
    800007a8:	00000097          	auipc	ra,0x0
    800007ac:	544080e7          	jalr	1348(ra) # 80000cec <release>
}
    800007b0:	bfc1                	j	80000780 <printf+0x1d6>

00000000800007b2 <printfinit>:
    ;
}

void
printfinit(void)
{
    800007b2:	1101                	addi	sp,sp,-32
    800007b4:	ec06                	sd	ra,24(sp)
    800007b6:	e822                	sd	s0,16(sp)
    800007b8:	e426                	sd	s1,8(sp)
    800007ba:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007bc:	00013497          	auipc	s1,0x13
    800007c0:	ecc48493          	addi	s1,s1,-308 # 80013688 <pr>
    800007c4:	00008597          	auipc	a1,0x8
    800007c8:	86c58593          	addi	a1,a1,-1940 # 80008030 <etext+0x30>
    800007cc:	8526                	mv	a0,s1
    800007ce:	00000097          	auipc	ra,0x0
    800007d2:	3da080e7          	jalr	986(ra) # 80000ba8 <initlock>
  pr.locking = 1;
    800007d6:	4785                	li	a5,1
    800007d8:	cc9c                	sw	a5,24(s1)
}
    800007da:	60e2                	ld	ra,24(sp)
    800007dc:	6442                	ld	s0,16(sp)
    800007de:	64a2                	ld	s1,8(sp)
    800007e0:	6105                	addi	sp,sp,32
    800007e2:	8082                	ret

00000000800007e4 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007e4:	1141                	addi	sp,sp,-16
    800007e6:	e406                	sd	ra,8(sp)
    800007e8:	e022                	sd	s0,0(sp)
    800007ea:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ec:	100007b7          	lui	a5,0x10000
    800007f0:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007f4:	10000737          	lui	a4,0x10000
    800007f8:	f8000693          	li	a3,-128
    800007fc:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000800:	468d                	li	a3,3
    80000802:	10000637          	lui	a2,0x10000
    80000806:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000080a:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000080e:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000812:	10000737          	lui	a4,0x10000
    80000816:	461d                	li	a2,7
    80000818:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000081c:	00d780a3          	sb	a3,1(a5)

  initlock(&uart_tx_lock, "uart");
    80000820:	00008597          	auipc	a1,0x8
    80000824:	81858593          	addi	a1,a1,-2024 # 80008038 <etext+0x38>
    80000828:	00013517          	auipc	a0,0x13
    8000082c:	e8050513          	addi	a0,a0,-384 # 800136a8 <uart_tx_lock>
    80000830:	00000097          	auipc	ra,0x0
    80000834:	378080e7          	jalr	888(ra) # 80000ba8 <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000840:	1101                	addi	sp,sp,-32
    80000842:	ec06                	sd	ra,24(sp)
    80000844:	e822                	sd	s0,16(sp)
    80000846:	e426                	sd	s1,8(sp)
    80000848:	1000                	addi	s0,sp,32
    8000084a:	84aa                	mv	s1,a0
  push_off();
    8000084c:	00000097          	auipc	ra,0x0
    80000850:	3a0080e7          	jalr	928(ra) # 80000bec <push_off>

  if(panicked){
    80000854:	0000b797          	auipc	a5,0xb
    80000858:	c0c7a783          	lw	a5,-1012(a5) # 8000b460 <panicked>
    8000085c:	eb85                	bnez	a5,8000088c <uartputc_sync+0x4c>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000085e:	10000737          	lui	a4,0x10000
    80000862:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000864:	00074783          	lbu	a5,0(a4)
    80000868:	0207f793          	andi	a5,a5,32
    8000086c:	dfe5                	beqz	a5,80000864 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000086e:	0ff4f513          	zext.b	a0,s1
    80000872:	100007b7          	lui	a5,0x10000
    80000876:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	412080e7          	jalr	1042(ra) # 80000c8c <pop_off>
}
    80000882:	60e2                	ld	ra,24(sp)
    80000884:	6442                	ld	s0,16(sp)
    80000886:	64a2                	ld	s1,8(sp)
    80000888:	6105                	addi	sp,sp,32
    8000088a:	8082                	ret
    for(;;)
    8000088c:	a001                	j	8000088c <uartputc_sync+0x4c>

000000008000088e <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000088e:	0000b797          	auipc	a5,0xb
    80000892:	bda7b783          	ld	a5,-1062(a5) # 8000b468 <uart_tx_r>
    80000896:	0000b717          	auipc	a4,0xb
    8000089a:	bda73703          	ld	a4,-1062(a4) # 8000b470 <uart_tx_w>
    8000089e:	06f70f63          	beq	a4,a5,8000091c <uartstart+0x8e>
{
    800008a2:	7139                	addi	sp,sp,-64
    800008a4:	fc06                	sd	ra,56(sp)
    800008a6:	f822                	sd	s0,48(sp)
    800008a8:	f426                	sd	s1,40(sp)
    800008aa:	f04a                	sd	s2,32(sp)
    800008ac:	ec4e                	sd	s3,24(sp)
    800008ae:	e852                	sd	s4,16(sp)
    800008b0:	e456                	sd	s5,8(sp)
    800008b2:	e05a                	sd	s6,0(sp)
    800008b4:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008b6:	10000937          	lui	s2,0x10000
    800008ba:	0915                	addi	s2,s2,5 # 10000005 <_entry-0x6ffffffb>
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008bc:	00013a97          	auipc	s5,0x13
    800008c0:	deca8a93          	addi	s5,s5,-532 # 800136a8 <uart_tx_lock>
    uart_tx_r += 1;
    800008c4:	0000b497          	auipc	s1,0xb
    800008c8:	ba448493          	addi	s1,s1,-1116 # 8000b468 <uart_tx_r>
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    
    WriteReg(THR, c);
    800008cc:	10000a37          	lui	s4,0x10000
    if(uart_tx_w == uart_tx_r){
    800008d0:	0000b997          	auipc	s3,0xb
    800008d4:	ba098993          	addi	s3,s3,-1120 # 8000b470 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008d8:	00094703          	lbu	a4,0(s2)
    800008dc:	02077713          	andi	a4,a4,32
    800008e0:	c705                	beqz	a4,80000908 <uartstart+0x7a>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    800008e2:	01f7f713          	andi	a4,a5,31
    800008e6:	9756                	add	a4,a4,s5
    800008e8:	01874b03          	lbu	s6,24(a4)
    uart_tx_r += 1;
    800008ec:	0785                	addi	a5,a5,1
    800008ee:	e09c                	sd	a5,0(s1)
    wakeup(&uart_tx_r);
    800008f0:	8526                	mv	a0,s1
    800008f2:	00002097          	auipc	ra,0x2
    800008f6:	ce2080e7          	jalr	-798(ra) # 800025d4 <wakeup>
    WriteReg(THR, c);
    800008fa:	016a0023          	sb	s6,0(s4) # 10000000 <_entry-0x70000000>
    if(uart_tx_w == uart_tx_r){
    800008fe:	609c                	ld	a5,0(s1)
    80000900:	0009b703          	ld	a4,0(s3)
    80000904:	fcf71ae3          	bne	a4,a5,800008d8 <uartstart+0x4a>
  }
}
    80000908:	70e2                	ld	ra,56(sp)
    8000090a:	7442                	ld	s0,48(sp)
    8000090c:	74a2                	ld	s1,40(sp)
    8000090e:	7902                	ld	s2,32(sp)
    80000910:	69e2                	ld	s3,24(sp)
    80000912:	6a42                	ld	s4,16(sp)
    80000914:	6aa2                	ld	s5,8(sp)
    80000916:	6b02                	ld	s6,0(sp)
    80000918:	6121                	addi	sp,sp,64
    8000091a:	8082                	ret
    8000091c:	8082                	ret

000000008000091e <uartputc>:
{
    8000091e:	7179                	addi	sp,sp,-48
    80000920:	f406                	sd	ra,40(sp)
    80000922:	f022                	sd	s0,32(sp)
    80000924:	ec26                	sd	s1,24(sp)
    80000926:	e84a                	sd	s2,16(sp)
    80000928:	e44e                	sd	s3,8(sp)
    8000092a:	e052                	sd	s4,0(sp)
    8000092c:	1800                	addi	s0,sp,48
    8000092e:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    80000930:	00013517          	auipc	a0,0x13
    80000934:	d7850513          	addi	a0,a0,-648 # 800136a8 <uart_tx_lock>
    80000938:	00000097          	auipc	ra,0x0
    8000093c:	300080e7          	jalr	768(ra) # 80000c38 <acquire>
  if(panicked){
    80000940:	0000b797          	auipc	a5,0xb
    80000944:	b207a783          	lw	a5,-1248(a5) # 8000b460 <panicked>
    80000948:	e7c9                	bnez	a5,800009d2 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000094a:	0000b717          	auipc	a4,0xb
    8000094e:	b2673703          	ld	a4,-1242(a4) # 8000b470 <uart_tx_w>
    80000952:	0000b797          	auipc	a5,0xb
    80000956:	b167b783          	ld	a5,-1258(a5) # 8000b468 <uart_tx_r>
    8000095a:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000095e:	00013997          	auipc	s3,0x13
    80000962:	d4a98993          	addi	s3,s3,-694 # 800136a8 <uart_tx_lock>
    80000966:	0000b497          	auipc	s1,0xb
    8000096a:	b0248493          	addi	s1,s1,-1278 # 8000b468 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000096e:	0000b917          	auipc	s2,0xb
    80000972:	b0290913          	addi	s2,s2,-1278 # 8000b470 <uart_tx_w>
    80000976:	00e79f63          	bne	a5,a4,80000994 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000097a:	85ce                	mv	a1,s3
    8000097c:	8526                	mv	a0,s1
    8000097e:	00002097          	auipc	ra,0x2
    80000982:	bd8080e7          	jalr	-1064(ra) # 80002556 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000986:	00093703          	ld	a4,0(s2)
    8000098a:	609c                	ld	a5,0(s1)
    8000098c:	02078793          	addi	a5,a5,32
    80000990:	fee785e3          	beq	a5,a4,8000097a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000994:	00013497          	auipc	s1,0x13
    80000998:	d1448493          	addi	s1,s1,-748 # 800136a8 <uart_tx_lock>
    8000099c:	01f77793          	andi	a5,a4,31
    800009a0:	97a6                	add	a5,a5,s1
    800009a2:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    800009a6:	0705                	addi	a4,a4,1
    800009a8:	0000b797          	auipc	a5,0xb
    800009ac:	ace7b423          	sd	a4,-1336(a5) # 8000b470 <uart_tx_w>
  uartstart();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	ede080e7          	jalr	-290(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    800009b8:	8526                	mv	a0,s1
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	332080e7          	jalr	818(ra) # 80000cec <release>
}
    800009c2:	70a2                	ld	ra,40(sp)
    800009c4:	7402                	ld	s0,32(sp)
    800009c6:	64e2                	ld	s1,24(sp)
    800009c8:	6942                	ld	s2,16(sp)
    800009ca:	69a2                	ld	s3,8(sp)
    800009cc:	6a02                	ld	s4,0(sp)
    800009ce:	6145                	addi	sp,sp,48
    800009d0:	8082                	ret
    for(;;)
    800009d2:	a001                	j	800009d2 <uartputc+0xb4>

00000000800009d4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009d4:	1141                	addi	sp,sp,-16
    800009d6:	e422                	sd	s0,8(sp)
    800009d8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009da:	100007b7          	lui	a5,0x10000
    800009de:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009e0:	0007c783          	lbu	a5,0(a5)
    800009e4:	8b85                	andi	a5,a5,1
    800009e6:	cb81                	beqz	a5,800009f6 <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    800009e8:	100007b7          	lui	a5,0x10000
    800009ec:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009f0:	6422                	ld	s0,8(sp)
    800009f2:	0141                	addi	sp,sp,16
    800009f4:	8082                	ret
    return -1;
    800009f6:	557d                	li	a0,-1
    800009f8:	bfe5                	j	800009f0 <uartgetc+0x1c>

00000000800009fa <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009fa:	1101                	addi	sp,sp,-32
    800009fc:	ec06                	sd	ra,24(sp)
    800009fe:	e822                	sd	s0,16(sp)
    80000a00:	e426                	sd	s1,8(sp)
    80000a02:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a04:	54fd                	li	s1,-1
    80000a06:	a029                	j	80000a10 <uartintr+0x16>
      break;
    consoleintr(c);
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	8ce080e7          	jalr	-1842(ra) # 800002d6 <consoleintr>
    int c = uartgetc();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	fc4080e7          	jalr	-60(ra) # 800009d4 <uartgetc>
    if(c == -1)
    80000a18:	fe9518e3          	bne	a0,s1,80000a08 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a1c:	00013497          	auipc	s1,0x13
    80000a20:	c8c48493          	addi	s1,s1,-884 # 800136a8 <uart_tx_lock>
    80000a24:	8526                	mv	a0,s1
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	212080e7          	jalr	530(ra) # 80000c38 <acquire>
  uartstart();
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	e60080e7          	jalr	-416(ra) # 8000088e <uartstart>
  release(&uart_tx_lock);
    80000a36:	8526                	mv	a0,s1
    80000a38:	00000097          	auipc	ra,0x0
    80000a3c:	2b4080e7          	jalr	692(ra) # 80000cec <release>
}
    80000a40:	60e2                	ld	ra,24(sp)
    80000a42:	6442                	ld	s0,16(sp)
    80000a44:	64a2                	ld	s1,8(sp)
    80000a46:	6105                	addi	sp,sp,32
    80000a48:	8082                	ret

0000000080000a4a <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a4a:	1101                	addi	sp,sp,-32
    80000a4c:	ec06                	sd	ra,24(sp)
    80000a4e:	e822                	sd	s0,16(sp)
    80000a50:	e426                	sd	s1,8(sp)
    80000a52:	e04a                	sd	s2,0(sp)
    80000a54:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a56:	03451793          	slli	a5,a0,0x34
    80000a5a:	ebb9                	bnez	a5,80000ab0 <kfree+0x66>
    80000a5c:	84aa                	mv	s1,a0
    80000a5e:	00027797          	auipc	a5,0x27
    80000a62:	6f278793          	addi	a5,a5,1778 # 80028150 <end>
    80000a66:	04f56563          	bltu	a0,a5,80000ab0 <kfree+0x66>
    80000a6a:	47c5                	li	a5,17
    80000a6c:	07ee                	slli	a5,a5,0x1b
    80000a6e:	04f57163          	bgeu	a0,a5,80000ab0 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a72:	6605                	lui	a2,0x1
    80000a74:	4585                	li	a1,1
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	2be080e7          	jalr	702(ra) # 80000d34 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a7e:	00013917          	auipc	s2,0x13
    80000a82:	c6290913          	addi	s2,s2,-926 # 800136e0 <kmem>
    80000a86:	854a                	mv	a0,s2
    80000a88:	00000097          	auipc	ra,0x0
    80000a8c:	1b0080e7          	jalr	432(ra) # 80000c38 <acquire>
  r->next = kmem.freelist;
    80000a90:	01893783          	ld	a5,24(s2)
    80000a94:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a96:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a9a:	854a                	mv	a0,s2
    80000a9c:	00000097          	auipc	ra,0x0
    80000aa0:	250080e7          	jalr	592(ra) # 80000cec <release>
}
    80000aa4:	60e2                	ld	ra,24(sp)
    80000aa6:	6442                	ld	s0,16(sp)
    80000aa8:	64a2                	ld	s1,8(sp)
    80000aaa:	6902                	ld	s2,0(sp)
    80000aac:	6105                	addi	sp,sp,32
    80000aae:	8082                	ret
    panic("kfree");
    80000ab0:	00007517          	auipc	a0,0x7
    80000ab4:	59050513          	addi	a0,a0,1424 # 80008040 <etext+0x40>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	aa8080e7          	jalr	-1368(ra) # 80000560 <panic>

0000000080000ac0 <freerange>:
{
    80000ac0:	7179                	addi	sp,sp,-48
    80000ac2:	f406                	sd	ra,40(sp)
    80000ac4:	f022                	sd	s0,32(sp)
    80000ac6:	ec26                	sd	s1,24(sp)
    80000ac8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aca:	6785                	lui	a5,0x1
    80000acc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000ad0:	00e504b3          	add	s1,a0,a4
    80000ad4:	777d                	lui	a4,0xfffff
    80000ad6:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ad8:	94be                	add	s1,s1,a5
    80000ada:	0295e463          	bltu	a1,s1,80000b02 <freerange+0x42>
    80000ade:	e84a                	sd	s2,16(sp)
    80000ae0:	e44e                	sd	s3,8(sp)
    80000ae2:	e052                	sd	s4,0(sp)
    80000ae4:	892e                	mv	s2,a1
    kfree(p);
    80000ae6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae8:	6985                	lui	s3,0x1
    kfree(p);
    80000aea:	01448533          	add	a0,s1,s4
    80000aee:	00000097          	auipc	ra,0x0
    80000af2:	f5c080e7          	jalr	-164(ra) # 80000a4a <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af6:	94ce                	add	s1,s1,s3
    80000af8:	fe9979e3          	bgeu	s2,s1,80000aea <freerange+0x2a>
    80000afc:	6942                	ld	s2,16(sp)
    80000afe:	69a2                	ld	s3,8(sp)
    80000b00:	6a02                	ld	s4,0(sp)
}
    80000b02:	70a2                	ld	ra,40(sp)
    80000b04:	7402                	ld	s0,32(sp)
    80000b06:	64e2                	ld	s1,24(sp)
    80000b08:	6145                	addi	sp,sp,48
    80000b0a:	8082                	ret

0000000080000b0c <kinit>:
{
    80000b0c:	1141                	addi	sp,sp,-16
    80000b0e:	e406                	sd	ra,8(sp)
    80000b10:	e022                	sd	s0,0(sp)
    80000b12:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b14:	00007597          	auipc	a1,0x7
    80000b18:	53458593          	addi	a1,a1,1332 # 80008048 <etext+0x48>
    80000b1c:	00013517          	auipc	a0,0x13
    80000b20:	bc450513          	addi	a0,a0,-1084 # 800136e0 <kmem>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	084080e7          	jalr	132(ra) # 80000ba8 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b2c:	45c5                	li	a1,17
    80000b2e:	05ee                	slli	a1,a1,0x1b
    80000b30:	00027517          	auipc	a0,0x27
    80000b34:	62050513          	addi	a0,a0,1568 # 80028150 <end>
    80000b38:	00000097          	auipc	ra,0x0
    80000b3c:	f88080e7          	jalr	-120(ra) # 80000ac0 <freerange>
}
    80000b40:	60a2                	ld	ra,8(sp)
    80000b42:	6402                	ld	s0,0(sp)
    80000b44:	0141                	addi	sp,sp,16
    80000b46:	8082                	ret

0000000080000b48 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b48:	1101                	addi	sp,sp,-32
    80000b4a:	ec06                	sd	ra,24(sp)
    80000b4c:	e822                	sd	s0,16(sp)
    80000b4e:	e426                	sd	s1,8(sp)
    80000b50:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b52:	00013497          	auipc	s1,0x13
    80000b56:	b8e48493          	addi	s1,s1,-1138 # 800136e0 <kmem>
    80000b5a:	8526                	mv	a0,s1
    80000b5c:	00000097          	auipc	ra,0x0
    80000b60:	0dc080e7          	jalr	220(ra) # 80000c38 <acquire>
  r = kmem.freelist;
    80000b64:	6c84                	ld	s1,24(s1)
  if(r)
    80000b66:	c885                	beqz	s1,80000b96 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b68:	609c                	ld	a5,0(s1)
    80000b6a:	00013517          	auipc	a0,0x13
    80000b6e:	b7650513          	addi	a0,a0,-1162 # 800136e0 <kmem>
    80000b72:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b74:	00000097          	auipc	ra,0x0
    80000b78:	178080e7          	jalr	376(ra) # 80000cec <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b7c:	6605                	lui	a2,0x1
    80000b7e:	4595                	li	a1,5
    80000b80:	8526                	mv	a0,s1
    80000b82:	00000097          	auipc	ra,0x0
    80000b86:	1b2080e7          	jalr	434(ra) # 80000d34 <memset>
  return (void*)r;
}
    80000b8a:	8526                	mv	a0,s1
    80000b8c:	60e2                	ld	ra,24(sp)
    80000b8e:	6442                	ld	s0,16(sp)
    80000b90:	64a2                	ld	s1,8(sp)
    80000b92:	6105                	addi	sp,sp,32
    80000b94:	8082                	ret
  release(&kmem.lock);
    80000b96:	00013517          	auipc	a0,0x13
    80000b9a:	b4a50513          	addi	a0,a0,-1206 # 800136e0 <kmem>
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	14e080e7          	jalr	334(ra) # 80000cec <release>
  if(r)
    80000ba6:	b7d5                	j	80000b8a <kalloc+0x42>

0000000080000ba8 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba8:	1141                	addi	sp,sp,-16
    80000baa:	e422                	sd	s0,8(sp)
    80000bac:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bae:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bb0:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb4:	00053823          	sd	zero,16(a0)
}
    80000bb8:	6422                	ld	s0,8(sp)
    80000bba:	0141                	addi	sp,sp,16
    80000bbc:	8082                	ret

0000000080000bbe <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bbe:	411c                	lw	a5,0(a0)
    80000bc0:	e399                	bnez	a5,80000bc6 <holding+0x8>
    80000bc2:	4501                	li	a0,0
  return r;
}
    80000bc4:	8082                	ret
{
    80000bc6:	1101                	addi	sp,sp,-32
    80000bc8:	ec06                	sd	ra,24(sp)
    80000bca:	e822                	sd	s0,16(sp)
    80000bcc:	e426                	sd	s1,8(sp)
    80000bce:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bd0:	6904                	ld	s1,16(a0)
    80000bd2:	00001097          	auipc	ra,0x1
    80000bd6:	146080e7          	jalr	326(ra) # 80001d18 <mycpu>
    80000bda:	40a48533          	sub	a0,s1,a0
    80000bde:	00153513          	seqz	a0,a0
}
    80000be2:	60e2                	ld	ra,24(sp)
    80000be4:	6442                	ld	s0,16(sp)
    80000be6:	64a2                	ld	s1,8(sp)
    80000be8:	6105                	addi	sp,sp,32
    80000bea:	8082                	ret

0000000080000bec <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bec:	1101                	addi	sp,sp,-32
    80000bee:	ec06                	sd	ra,24(sp)
    80000bf0:	e822                	sd	s0,16(sp)
    80000bf2:	e426                	sd	s1,8(sp)
    80000bf4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf6:	100024f3          	csrr	s1,sstatus
    80000bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c00:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c04:	00001097          	auipc	ra,0x1
    80000c08:	114080e7          	jalr	276(ra) # 80001d18 <mycpu>
    80000c0c:	5d3c                	lw	a5,120(a0)
    80000c0e:	cf89                	beqz	a5,80000c28 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c10:	00001097          	auipc	ra,0x1
    80000c14:	108080e7          	jalr	264(ra) # 80001d18 <mycpu>
    80000c18:	5d3c                	lw	a5,120(a0)
    80000c1a:	2785                	addiw	a5,a5,1
    80000c1c:	dd3c                	sw	a5,120(a0)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    mycpu()->intena = old;
    80000c28:	00001097          	auipc	ra,0x1
    80000c2c:	0f0080e7          	jalr	240(ra) # 80001d18 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c30:	8085                	srli	s1,s1,0x1
    80000c32:	8885                	andi	s1,s1,1
    80000c34:	dd64                	sw	s1,124(a0)
    80000c36:	bfe9                	j	80000c10 <push_off+0x24>

0000000080000c38 <acquire>:
{
    80000c38:	1101                	addi	sp,sp,-32
    80000c3a:	ec06                	sd	ra,24(sp)
    80000c3c:	e822                	sd	s0,16(sp)
    80000c3e:	e426                	sd	s1,8(sp)
    80000c40:	1000                	addi	s0,sp,32
    80000c42:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	fa8080e7          	jalr	-88(ra) # 80000bec <push_off>
  if(holding(lk))
    80000c4c:	8526                	mv	a0,s1
    80000c4e:	00000097          	auipc	ra,0x0
    80000c52:	f70080e7          	jalr	-144(ra) # 80000bbe <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c56:	4705                	li	a4,1
  if(holding(lk))
    80000c58:	e115                	bnez	a0,80000c7c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c5a:	87ba                	mv	a5,a4
    80000c5c:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c60:	2781                	sext.w	a5,a5
    80000c62:	ffe5                	bnez	a5,80000c5a <acquire+0x22>
  __sync_synchronize();
    80000c64:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000c68:	00001097          	auipc	ra,0x1
    80000c6c:	0b0080e7          	jalr	176(ra) # 80001d18 <mycpu>
    80000c70:	e888                	sd	a0,16(s1)
}
    80000c72:	60e2                	ld	ra,24(sp)
    80000c74:	6442                	ld	s0,16(sp)
    80000c76:	64a2                	ld	s1,8(sp)
    80000c78:	6105                	addi	sp,sp,32
    80000c7a:	8082                	ret
    panic("acquire");
    80000c7c:	00007517          	auipc	a0,0x7
    80000c80:	3d450513          	addi	a0,a0,980 # 80008050 <etext+0x50>
    80000c84:	00000097          	auipc	ra,0x0
    80000c88:	8dc080e7          	jalr	-1828(ra) # 80000560 <panic>

0000000080000c8c <pop_off>:

void
pop_off(void)
{
    80000c8c:	1141                	addi	sp,sp,-16
    80000c8e:	e406                	sd	ra,8(sp)
    80000c90:	e022                	sd	s0,0(sp)
    80000c92:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c94:	00001097          	auipc	ra,0x1
    80000c98:	084080e7          	jalr	132(ra) # 80001d18 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000ca0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000ca2:	e78d                	bnez	a5,80000ccc <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca4:	5d3c                	lw	a5,120(a0)
    80000ca6:	02f05b63          	blez	a5,80000cdc <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000caa:	37fd                	addiw	a5,a5,-1
    80000cac:	0007871b          	sext.w	a4,a5
    80000cb0:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cb2:	eb09                	bnez	a4,80000cc4 <pop_off+0x38>
    80000cb4:	5d7c                	lw	a5,124(a0)
    80000cb6:	c799                	beqz	a5,80000cc4 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cc0:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc4:	60a2                	ld	ra,8(sp)
    80000cc6:	6402                	ld	s0,0(sp)
    80000cc8:	0141                	addi	sp,sp,16
    80000cca:	8082                	ret
    panic("pop_off - interruptible");
    80000ccc:	00007517          	auipc	a0,0x7
    80000cd0:	38c50513          	addi	a0,a0,908 # 80008058 <etext+0x58>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	88c080e7          	jalr	-1908(ra) # 80000560 <panic>
    panic("pop_off");
    80000cdc:	00007517          	auipc	a0,0x7
    80000ce0:	39450513          	addi	a0,a0,916 # 80008070 <etext+0x70>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	87c080e7          	jalr	-1924(ra) # 80000560 <panic>

0000000080000cec <release>:
{
    80000cec:	1101                	addi	sp,sp,-32
    80000cee:	ec06                	sd	ra,24(sp)
    80000cf0:	e822                	sd	s0,16(sp)
    80000cf2:	e426                	sd	s1,8(sp)
    80000cf4:	1000                	addi	s0,sp,32
    80000cf6:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf8:	00000097          	auipc	ra,0x0
    80000cfc:	ec6080e7          	jalr	-314(ra) # 80000bbe <holding>
    80000d00:	c115                	beqz	a0,80000d24 <release+0x38>
  lk->cpu = 0;
    80000d02:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d06:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000d0a:	0310000f          	fence	rw,w
    80000d0e:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000d12:	00000097          	auipc	ra,0x0
    80000d16:	f7a080e7          	jalr	-134(ra) # 80000c8c <pop_off>
}
    80000d1a:	60e2                	ld	ra,24(sp)
    80000d1c:	6442                	ld	s0,16(sp)
    80000d1e:	64a2                	ld	s1,8(sp)
    80000d20:	6105                	addi	sp,sp,32
    80000d22:	8082                	ret
    panic("release");
    80000d24:	00007517          	auipc	a0,0x7
    80000d28:	35450513          	addi	a0,a0,852 # 80008078 <etext+0x78>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	834080e7          	jalr	-1996(ra) # 80000560 <panic>

0000000080000d34 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d34:	1141                	addi	sp,sp,-16
    80000d36:	e422                	sd	s0,8(sp)
    80000d38:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d3a:	ca19                	beqz	a2,80000d50 <memset+0x1c>
    80000d3c:	87aa                	mv	a5,a0
    80000d3e:	1602                	slli	a2,a2,0x20
    80000d40:	9201                	srli	a2,a2,0x20
    80000d42:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4a:	0785                	addi	a5,a5,1
    80000d4c:	fee79de3          	bne	a5,a4,80000d46 <memset+0x12>
  }
  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret

0000000080000d56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5c:	ca05                	beqz	a2,80000d8c <memcmp+0x36>
    80000d5e:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d62:	1682                	slli	a3,a3,0x20
    80000d64:	9281                	srli	a3,a3,0x20
    80000d66:	0685                	addi	a3,a3,1
    80000d68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6a:	00054783          	lbu	a5,0(a0)
    80000d6e:	0005c703          	lbu	a4,0(a1)
    80000d72:	00e79863          	bne	a5,a4,80000d82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d76:	0505                	addi	a0,a0,1
    80000d78:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d7a:	fed518e3          	bne	a0,a3,80000d6a <memcmp+0x14>
  }

  return 0;
    80000d7e:	4501                	li	a0,0
    80000d80:	a019                	j	80000d86 <memcmp+0x30>
      return *s1 - *s2;
    80000d82:	40e7853b          	subw	a0,a5,a4
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	addi	sp,sp,16
    80000d8a:	8082                	ret
  return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	bfe5                	j	80000d86 <memcmp+0x30>

0000000080000d90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d96:	c205                	beqz	a2,80000db6 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d98:	02a5e263          	bltu	a1,a0,80000dbc <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d9c:	1602                	slli	a2,a2,0x20
    80000d9e:	9201                	srli	a2,a2,0x20
    80000da0:	00c587b3          	add	a5,a1,a2
{
    80000da4:	872a                	mv	a4,a0
      *d++ = *s++;
    80000da6:	0585                	addi	a1,a1,1
    80000da8:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd6eb1>
    80000daa:	fff5c683          	lbu	a3,-1(a1)
    80000dae:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000db2:	feb79ae3          	bne	a5,a1,80000da6 <memmove+0x16>

  return dst;
}
    80000db6:	6422                	ld	s0,8(sp)
    80000db8:	0141                	addi	sp,sp,16
    80000dba:	8082                	ret
  if(s < d && s + n > d){
    80000dbc:	02061693          	slli	a3,a2,0x20
    80000dc0:	9281                	srli	a3,a3,0x20
    80000dc2:	00d58733          	add	a4,a1,a3
    80000dc6:	fce57be3          	bgeu	a0,a4,80000d9c <memmove+0xc>
    d += n;
    80000dca:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000dcc:	fff6079b          	addiw	a5,a2,-1
    80000dd0:	1782                	slli	a5,a5,0x20
    80000dd2:	9381                	srli	a5,a5,0x20
    80000dd4:	fff7c793          	not	a5,a5
    80000dd8:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dda:	177d                	addi	a4,a4,-1
    80000ddc:	16fd                	addi	a3,a3,-1
    80000dde:	00074603          	lbu	a2,0(a4)
    80000de2:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000de6:	fef71ae3          	bne	a4,a5,80000dda <memmove+0x4a>
    80000dea:	b7f1                	j	80000db6 <memmove+0x26>

0000000080000dec <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dec:	1141                	addi	sp,sp,-16
    80000dee:	e406                	sd	ra,8(sp)
    80000df0:	e022                	sd	s0,0(sp)
    80000df2:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000df4:	00000097          	auipc	ra,0x0
    80000df8:	f9c080e7          	jalr	-100(ra) # 80000d90 <memmove>
}
    80000dfc:	60a2                	ld	ra,8(sp)
    80000dfe:	6402                	ld	s0,0(sp)
    80000e00:	0141                	addi	sp,sp,16
    80000e02:	8082                	ret

0000000080000e04 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e04:	1141                	addi	sp,sp,-16
    80000e06:	e422                	sd	s0,8(sp)
    80000e08:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e0a:	ce11                	beqz	a2,80000e26 <strncmp+0x22>
    80000e0c:	00054783          	lbu	a5,0(a0)
    80000e10:	cf89                	beqz	a5,80000e2a <strncmp+0x26>
    80000e12:	0005c703          	lbu	a4,0(a1)
    80000e16:	00f71a63          	bne	a4,a5,80000e2a <strncmp+0x26>
    n--, p++, q++;
    80000e1a:	367d                	addiw	a2,a2,-1
    80000e1c:	0505                	addi	a0,a0,1
    80000e1e:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e20:	f675                	bnez	a2,80000e0c <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e22:	4501                	li	a0,0
    80000e24:	a801                	j	80000e34 <strncmp+0x30>
    80000e26:	4501                	li	a0,0
    80000e28:	a031                	j	80000e34 <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000e2a:	00054503          	lbu	a0,0(a0)
    80000e2e:	0005c783          	lbu	a5,0(a1)
    80000e32:	9d1d                	subw	a0,a0,a5
}
    80000e34:	6422                	ld	s0,8(sp)
    80000e36:	0141                	addi	sp,sp,16
    80000e38:	8082                	ret

0000000080000e3a <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e3a:	1141                	addi	sp,sp,-16
    80000e3c:	e422                	sd	s0,8(sp)
    80000e3e:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e40:	87aa                	mv	a5,a0
    80000e42:	86b2                	mv	a3,a2
    80000e44:	367d                	addiw	a2,a2,-1
    80000e46:	02d05563          	blez	a3,80000e70 <strncpy+0x36>
    80000e4a:	0785                	addi	a5,a5,1
    80000e4c:	0005c703          	lbu	a4,0(a1)
    80000e50:	fee78fa3          	sb	a4,-1(a5)
    80000e54:	0585                	addi	a1,a1,1
    80000e56:	f775                	bnez	a4,80000e42 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e58:	873e                	mv	a4,a5
    80000e5a:	9fb5                	addw	a5,a5,a3
    80000e5c:	37fd                	addiw	a5,a5,-1
    80000e5e:	00c05963          	blez	a2,80000e70 <strncpy+0x36>
    *s++ = 0;
    80000e62:	0705                	addi	a4,a4,1
    80000e64:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000e68:	40e786bb          	subw	a3,a5,a4
    80000e6c:	fed04be3          	bgtz	a3,80000e62 <strncpy+0x28>
  return os;
}
    80000e70:	6422                	ld	s0,8(sp)
    80000e72:	0141                	addi	sp,sp,16
    80000e74:	8082                	ret

0000000080000e76 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e76:	1141                	addi	sp,sp,-16
    80000e78:	e422                	sd	s0,8(sp)
    80000e7a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e7c:	02c05363          	blez	a2,80000ea2 <safestrcpy+0x2c>
    80000e80:	fff6069b          	addiw	a3,a2,-1
    80000e84:	1682                	slli	a3,a3,0x20
    80000e86:	9281                	srli	a3,a3,0x20
    80000e88:	96ae                	add	a3,a3,a1
    80000e8a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e8c:	00d58963          	beq	a1,a3,80000e9e <safestrcpy+0x28>
    80000e90:	0585                	addi	a1,a1,1
    80000e92:	0785                	addi	a5,a5,1
    80000e94:	fff5c703          	lbu	a4,-1(a1)
    80000e98:	fee78fa3          	sb	a4,-1(a5)
    80000e9c:	fb65                	bnez	a4,80000e8c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e9e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000ea2:	6422                	ld	s0,8(sp)
    80000ea4:	0141                	addi	sp,sp,16
    80000ea6:	8082                	ret

0000000080000ea8 <strlen>:

int
strlen(const char *s)
{
    80000ea8:	1141                	addi	sp,sp,-16
    80000eaa:	e422                	sd	s0,8(sp)
    80000eac:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000eae:	00054783          	lbu	a5,0(a0)
    80000eb2:	cf91                	beqz	a5,80000ece <strlen+0x26>
    80000eb4:	0505                	addi	a0,a0,1
    80000eb6:	87aa                	mv	a5,a0
    80000eb8:	86be                	mv	a3,a5
    80000eba:	0785                	addi	a5,a5,1
    80000ebc:	fff7c703          	lbu	a4,-1(a5)
    80000ec0:	ff65                	bnez	a4,80000eb8 <strlen+0x10>
    80000ec2:	40a6853b          	subw	a0,a3,a0
    80000ec6:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000ec8:	6422                	ld	s0,8(sp)
    80000eca:	0141                	addi	sp,sp,16
    80000ecc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ece:	4501                	li	a0,0
    80000ed0:	bfe5                	j	80000ec8 <strlen+0x20>

0000000080000ed2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ed2:	1141                	addi	sp,sp,-16
    80000ed4:	e406                	sd	ra,8(sp)
    80000ed6:	e022                	sd	s0,0(sp)
    80000ed8:	0800                	addi	s0,sp,16
  // for(int i=0;i<32;i++){
  //   syscall_count[i] = 0;
  // }
  if(cpuid() == 0){
    80000eda:	00001097          	auipc	ra,0x1
    80000ede:	e2e080e7          	jalr	-466(ra) # 80001d08 <cpuid>
    userinit();      // first user process
    
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ee2:	0000a717          	auipc	a4,0xa
    80000ee6:	59670713          	addi	a4,a4,1430 # 8000b478 <started>
  if(cpuid() == 0){
    80000eea:	c139                	beqz	a0,80000f30 <main+0x5e>
    while(started == 0)
    80000eec:	431c                	lw	a5,0(a4)
    80000eee:	2781                	sext.w	a5,a5
    80000ef0:	dff5                	beqz	a5,80000eec <main+0x1a>
      ;
    __sync_synchronize();
    80000ef2:	0330000f          	fence	rw,rw
    // printf("bsdclnclwnlrvlrnlrfl\n");
    printf("hart %d starting\n", cpuid());
    80000ef6:	00001097          	auipc	ra,0x1
    80000efa:	e12080e7          	jalr	-494(ra) # 80001d08 <cpuid>
    80000efe:	85aa                	mv	a1,a0
    80000f00:	00007517          	auipc	a0,0x7
    80000f04:	19850513          	addi	a0,a0,408 # 80008098 <etext+0x98>
    80000f08:	fffff097          	auipc	ra,0xfffff
    80000f0c:	6a2080e7          	jalr	1698(ra) # 800005aa <printf>
    kvminithart();    // turn on paging
    80000f10:	00000097          	auipc	ra,0x0
    80000f14:	0d8080e7          	jalr	216(ra) # 80000fe8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f18:	00002097          	auipc	ra,0x2
    80000f1c:	e50080e7          	jalr	-432(ra) # 80002d68 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f20:	00006097          	auipc	ra,0x6
    80000f24:	844080e7          	jalr	-1980(ra) # 80006764 <plicinithart>
  }

  scheduler();        
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	33c080e7          	jalr	828(ra) # 80002264 <scheduler>
    consoleinit();
    80000f30:	fffff097          	auipc	ra,0xfffff
    80000f34:	540080e7          	jalr	1344(ra) # 80000470 <consoleinit>
    printfinit();
    80000f38:	00000097          	auipc	ra,0x0
    80000f3c:	87a080e7          	jalr	-1926(ra) # 800007b2 <printfinit>
    printf("\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	0d050513          	addi	a0,a0,208 # 80008010 <etext+0x10>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	662080e7          	jalr	1634(ra) # 800005aa <printf>
    printf("xv6 kernel is booting\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	13050513          	addi	a0,a0,304 # 80008080 <etext+0x80>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	652080e7          	jalr	1618(ra) # 800005aa <printf>
    printf("\n");
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	0b050513          	addi	a0,a0,176 # 80008010 <etext+0x10>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	642080e7          	jalr	1602(ra) # 800005aa <printf>
    kinit();         // physical page allocator
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	b9c080e7          	jalr	-1124(ra) # 80000b0c <kinit>
    kvminit();       // create kernel page table
    80000f78:	00000097          	auipc	ra,0x0
    80000f7c:	326080e7          	jalr	806(ra) # 8000129e <kvminit>
    kvminithart();   // turn on paging
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	068080e7          	jalr	104(ra) # 80000fe8 <kvminithart>
    procinit();      // process table
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	cae080e7          	jalr	-850(ra) # 80001c36 <procinit>
    trapinit();      // trap vectors
    80000f90:	00002097          	auipc	ra,0x2
    80000f94:	db0080e7          	jalr	-592(ra) # 80002d40 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f98:	00002097          	auipc	ra,0x2
    80000f9c:	dd0080e7          	jalr	-560(ra) # 80002d68 <trapinithart>
    plicinit();      // set up interrupt controller
    80000fa0:	00005097          	auipc	ra,0x5
    80000fa4:	7aa080e7          	jalr	1962(ra) # 8000674a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fa8:	00005097          	auipc	ra,0x5
    80000fac:	7bc080e7          	jalr	1980(ra) # 80006764 <plicinithart>
    binit();         // buffer cache
    80000fb0:	00003097          	auipc	ra,0x3
    80000fb4:	88a080e7          	jalr	-1910(ra) # 8000383a <binit>
    iinit();         // inode table
    80000fb8:	00003097          	auipc	ra,0x3
    80000fbc:	f40080e7          	jalr	-192(ra) # 80003ef8 <iinit>
    fileinit();      // file table
    80000fc0:	00004097          	auipc	ra,0x4
    80000fc4:	ef0080e7          	jalr	-272(ra) # 80004eb0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fc8:	00006097          	auipc	ra,0x6
    80000fcc:	8a4080e7          	jalr	-1884(ra) # 8000686c <virtio_disk_init>
    userinit();      // first user process
    80000fd0:	00001097          	auipc	ra,0x1
    80000fd4:	064080e7          	jalr	100(ra) # 80002034 <userinit>
    __sync_synchronize();
    80000fd8:	0330000f          	fence	rw,rw
    started = 1;
    80000fdc:	4785                	li	a5,1
    80000fde:	0000a717          	auipc	a4,0xa
    80000fe2:	48f72d23          	sw	a5,1178(a4) # 8000b478 <started>
    80000fe6:	b789                	j	80000f28 <main+0x56>

0000000080000fe8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fe8:	1141                	addi	sp,sp,-16
    80000fea:	e422                	sd	s0,8(sp)
    80000fec:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ff2:	0000a797          	auipc	a5,0xa
    80000ff6:	48e7b783          	ld	a5,1166(a5) # 8000b480 <kernel_pagetable>
    80000ffa:	83b1                	srli	a5,a5,0xc
    80000ffc:	577d                	li	a4,-1
    80000ffe:	177e                	slli	a4,a4,0x3f
    80001000:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001002:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001006:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000100a:	6422                	ld	s0,8(sp)
    8000100c:	0141                	addi	sp,sp,16
    8000100e:	8082                	ret

0000000080001010 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001010:	7139                	addi	sp,sp,-64
    80001012:	fc06                	sd	ra,56(sp)
    80001014:	f822                	sd	s0,48(sp)
    80001016:	f426                	sd	s1,40(sp)
    80001018:	f04a                	sd	s2,32(sp)
    8000101a:	ec4e                	sd	s3,24(sp)
    8000101c:	e852                	sd	s4,16(sp)
    8000101e:	e456                	sd	s5,8(sp)
    80001020:	e05a                	sd	s6,0(sp)
    80001022:	0080                	addi	s0,sp,64
    80001024:	84aa                	mv	s1,a0
    80001026:	89ae                	mv	s3,a1
    80001028:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000102a:	57fd                	li	a5,-1
    8000102c:	83e9                	srli	a5,a5,0x1a
    8000102e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001030:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001032:	04b7f263          	bgeu	a5,a1,80001076 <walk+0x66>
    panic("walk");
    80001036:	00007517          	auipc	a0,0x7
    8000103a:	07a50513          	addi	a0,a0,122 # 800080b0 <etext+0xb0>
    8000103e:	fffff097          	auipc	ra,0xfffff
    80001042:	522080e7          	jalr	1314(ra) # 80000560 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001046:	060a8663          	beqz	s5,800010b2 <walk+0xa2>
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	afe080e7          	jalr	-1282(ra) # 80000b48 <kalloc>
    80001052:	84aa                	mv	s1,a0
    80001054:	c529                	beqz	a0,8000109e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001056:	6605                	lui	a2,0x1
    80001058:	4581                	li	a1,0
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	cda080e7          	jalr	-806(ra) # 80000d34 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001062:	00c4d793          	srli	a5,s1,0xc
    80001066:	07aa                	slli	a5,a5,0xa
    80001068:	0017e793          	ori	a5,a5,1
    8000106c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001070:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd6ea7>
    80001072:	036a0063          	beq	s4,s6,80001092 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001076:	0149d933          	srl	s2,s3,s4
    8000107a:	1ff97913          	andi	s2,s2,511
    8000107e:	090e                	slli	s2,s2,0x3
    80001080:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001082:	00093483          	ld	s1,0(s2)
    80001086:	0014f793          	andi	a5,s1,1
    8000108a:	dfd5                	beqz	a5,80001046 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000108c:	80a9                	srli	s1,s1,0xa
    8000108e:	04b2                	slli	s1,s1,0xc
    80001090:	b7c5                	j	80001070 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001092:	00c9d513          	srli	a0,s3,0xc
    80001096:	1ff57513          	andi	a0,a0,511
    8000109a:	050e                	slli	a0,a0,0x3
    8000109c:	9526                	add	a0,a0,s1
}
    8000109e:	70e2                	ld	ra,56(sp)
    800010a0:	7442                	ld	s0,48(sp)
    800010a2:	74a2                	ld	s1,40(sp)
    800010a4:	7902                	ld	s2,32(sp)
    800010a6:	69e2                	ld	s3,24(sp)
    800010a8:	6a42                	ld	s4,16(sp)
    800010aa:	6aa2                	ld	s5,8(sp)
    800010ac:	6b02                	ld	s6,0(sp)
    800010ae:	6121                	addi	sp,sp,64
    800010b0:	8082                	ret
        return 0;
    800010b2:	4501                	li	a0,0
    800010b4:	b7ed                	j	8000109e <walk+0x8e>

00000000800010b6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010b6:	57fd                	li	a5,-1
    800010b8:	83e9                	srli	a5,a5,0x1a
    800010ba:	00b7f463          	bgeu	a5,a1,800010c2 <walkaddr+0xc>
    return 0;
    800010be:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010c0:	8082                	ret
{
    800010c2:	1141                	addi	sp,sp,-16
    800010c4:	e406                	sd	ra,8(sp)
    800010c6:	e022                	sd	s0,0(sp)
    800010c8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ca:	4601                	li	a2,0
    800010cc:	00000097          	auipc	ra,0x0
    800010d0:	f44080e7          	jalr	-188(ra) # 80001010 <walk>
  if(pte == 0)
    800010d4:	c105                	beqz	a0,800010f4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010d6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010d8:	0117f693          	andi	a3,a5,17
    800010dc:	4745                	li	a4,17
    return 0;
    800010de:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010e0:	00e68663          	beq	a3,a4,800010ec <walkaddr+0x36>
}
    800010e4:	60a2                	ld	ra,8(sp)
    800010e6:	6402                	ld	s0,0(sp)
    800010e8:	0141                	addi	sp,sp,16
    800010ea:	8082                	ret
  pa = PTE2PA(*pte);
    800010ec:	83a9                	srli	a5,a5,0xa
    800010ee:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010f2:	bfcd                	j	800010e4 <walkaddr+0x2e>
    return 0;
    800010f4:	4501                	li	a0,0
    800010f6:	b7fd                	j	800010e4 <walkaddr+0x2e>

00000000800010f8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010f8:	715d                	addi	sp,sp,-80
    800010fa:	e486                	sd	ra,72(sp)
    800010fc:	e0a2                	sd	s0,64(sp)
    800010fe:	fc26                	sd	s1,56(sp)
    80001100:	f84a                	sd	s2,48(sp)
    80001102:	f44e                	sd	s3,40(sp)
    80001104:	f052                	sd	s4,32(sp)
    80001106:	ec56                	sd	s5,24(sp)
    80001108:	e85a                	sd	s6,16(sp)
    8000110a:	e45e                	sd	s7,8(sp)
    8000110c:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000110e:	c639                	beqz	a2,8000115c <mappages+0x64>
    80001110:	8aaa                	mv	s5,a0
    80001112:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001114:	777d                	lui	a4,0xfffff
    80001116:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000111a:	fff58993          	addi	s3,a1,-1
    8000111e:	99b2                	add	s3,s3,a2
    80001120:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001124:	893e                	mv	s2,a5
    80001126:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000112a:	6b85                	lui	s7,0x1
    8000112c:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001130:	4605                	li	a2,1
    80001132:	85ca                	mv	a1,s2
    80001134:	8556                	mv	a0,s5
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	eda080e7          	jalr	-294(ra) # 80001010 <walk>
    8000113e:	cd1d                	beqz	a0,8000117c <mappages+0x84>
    if(*pte & PTE_V)
    80001140:	611c                	ld	a5,0(a0)
    80001142:	8b85                	andi	a5,a5,1
    80001144:	e785                	bnez	a5,8000116c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001146:	80b1                	srli	s1,s1,0xc
    80001148:	04aa                	slli	s1,s1,0xa
    8000114a:	0164e4b3          	or	s1,s1,s6
    8000114e:	0014e493          	ori	s1,s1,1
    80001152:	e104                	sd	s1,0(a0)
    if(a == last)
    80001154:	05390063          	beq	s2,s3,80001194 <mappages+0x9c>
    a += PGSIZE;
    80001158:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000115a:	bfc9                	j	8000112c <mappages+0x34>
    panic("mappages: size");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f5c50513          	addi	a0,a0,-164 # 800080b8 <etext+0xb8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3fc080e7          	jalr	1020(ra) # 80000560 <panic>
      panic("mappages: remap");
    8000116c:	00007517          	auipc	a0,0x7
    80001170:	f5c50513          	addi	a0,a0,-164 # 800080c8 <etext+0xc8>
    80001174:	fffff097          	auipc	ra,0xfffff
    80001178:	3ec080e7          	jalr	1004(ra) # 80000560 <panic>
      return -1;
    8000117c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000117e:	60a6                	ld	ra,72(sp)
    80001180:	6406                	ld	s0,64(sp)
    80001182:	74e2                	ld	s1,56(sp)
    80001184:	7942                	ld	s2,48(sp)
    80001186:	79a2                	ld	s3,40(sp)
    80001188:	7a02                	ld	s4,32(sp)
    8000118a:	6ae2                	ld	s5,24(sp)
    8000118c:	6b42                	ld	s6,16(sp)
    8000118e:	6ba2                	ld	s7,8(sp)
    80001190:	6161                	addi	sp,sp,80
    80001192:	8082                	ret
  return 0;
    80001194:	4501                	li	a0,0
    80001196:	b7e5                	j	8000117e <mappages+0x86>

0000000080001198 <kvmmap>:
{
    80001198:	1141                	addi	sp,sp,-16
    8000119a:	e406                	sd	ra,8(sp)
    8000119c:	e022                	sd	s0,0(sp)
    8000119e:	0800                	addi	s0,sp,16
    800011a0:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800011a2:	86b2                	mv	a3,a2
    800011a4:	863e                	mv	a2,a5
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	f52080e7          	jalr	-174(ra) # 800010f8 <mappages>
    800011ae:	e509                	bnez	a0,800011b8 <kvmmap+0x20>
}
    800011b0:	60a2                	ld	ra,8(sp)
    800011b2:	6402                	ld	s0,0(sp)
    800011b4:	0141                	addi	sp,sp,16
    800011b6:	8082                	ret
    panic("kvmmap");
    800011b8:	00007517          	auipc	a0,0x7
    800011bc:	f2050513          	addi	a0,a0,-224 # 800080d8 <etext+0xd8>
    800011c0:	fffff097          	auipc	ra,0xfffff
    800011c4:	3a0080e7          	jalr	928(ra) # 80000560 <panic>

00000000800011c8 <kvmmake>:
{
    800011c8:	1101                	addi	sp,sp,-32
    800011ca:	ec06                	sd	ra,24(sp)
    800011cc:	e822                	sd	s0,16(sp)
    800011ce:	e426                	sd	s1,8(sp)
    800011d0:	e04a                	sd	s2,0(sp)
    800011d2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011d4:	00000097          	auipc	ra,0x0
    800011d8:	974080e7          	jalr	-1676(ra) # 80000b48 <kalloc>
    800011dc:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011de:	6605                	lui	a2,0x1
    800011e0:	4581                	li	a1,0
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	b52080e7          	jalr	-1198(ra) # 80000d34 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ea:	4719                	li	a4,6
    800011ec:	6685                	lui	a3,0x1
    800011ee:	10000637          	lui	a2,0x10000
    800011f2:	100005b7          	lui	a1,0x10000
    800011f6:	8526                	mv	a0,s1
    800011f8:	00000097          	auipc	ra,0x0
    800011fc:	fa0080e7          	jalr	-96(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001200:	4719                	li	a4,6
    80001202:	6685                	lui	a3,0x1
    80001204:	10001637          	lui	a2,0x10001
    80001208:	100015b7          	lui	a1,0x10001
    8000120c:	8526                	mv	a0,s1
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	f8a080e7          	jalr	-118(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001216:	4719                	li	a4,6
    80001218:	004006b7          	lui	a3,0x400
    8000121c:	0c000637          	lui	a2,0xc000
    80001220:	0c0005b7          	lui	a1,0xc000
    80001224:	8526                	mv	a0,s1
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	f72080e7          	jalr	-142(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000122e:	00007917          	auipc	s2,0x7
    80001232:	dd290913          	addi	s2,s2,-558 # 80008000 <etext>
    80001236:	4729                	li	a4,10
    80001238:	80007697          	auipc	a3,0x80007
    8000123c:	dc868693          	addi	a3,a3,-568 # 8000 <_entry-0x7fff8000>
    80001240:	4605                	li	a2,1
    80001242:	067e                	slli	a2,a2,0x1f
    80001244:	85b2                	mv	a1,a2
    80001246:	8526                	mv	a0,s1
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	f50080e7          	jalr	-176(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001250:	46c5                	li	a3,17
    80001252:	06ee                	slli	a3,a3,0x1b
    80001254:	4719                	li	a4,6
    80001256:	412686b3          	sub	a3,a3,s2
    8000125a:	864a                	mv	a2,s2
    8000125c:	85ca                	mv	a1,s2
    8000125e:	8526                	mv	a0,s1
    80001260:	00000097          	auipc	ra,0x0
    80001264:	f38080e7          	jalr	-200(ra) # 80001198 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001268:	4729                	li	a4,10
    8000126a:	6685                	lui	a3,0x1
    8000126c:	00006617          	auipc	a2,0x6
    80001270:	d9460613          	addi	a2,a2,-620 # 80007000 <_trampoline>
    80001274:	040005b7          	lui	a1,0x4000
    80001278:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000127a:	05b2                	slli	a1,a1,0xc
    8000127c:	8526                	mv	a0,s1
    8000127e:	00000097          	auipc	ra,0x0
    80001282:	f1a080e7          	jalr	-230(ra) # 80001198 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001286:	8526                	mv	a0,s1
    80001288:	00001097          	auipc	ra,0x1
    8000128c:	90a080e7          	jalr	-1782(ra) # 80001b92 <proc_mapstacks>
}
    80001290:	8526                	mv	a0,s1
    80001292:	60e2                	ld	ra,24(sp)
    80001294:	6442                	ld	s0,16(sp)
    80001296:	64a2                	ld	s1,8(sp)
    80001298:	6902                	ld	s2,0(sp)
    8000129a:	6105                	addi	sp,sp,32
    8000129c:	8082                	ret

000000008000129e <kvminit>:
{
    8000129e:	1141                	addi	sp,sp,-16
    800012a0:	e406                	sd	ra,8(sp)
    800012a2:	e022                	sd	s0,0(sp)
    800012a4:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800012a6:	00000097          	auipc	ra,0x0
    800012aa:	f22080e7          	jalr	-222(ra) # 800011c8 <kvmmake>
    800012ae:	0000a797          	auipc	a5,0xa
    800012b2:	1ca7b923          	sd	a0,466(a5) # 8000b480 <kernel_pagetable>
}
    800012b6:	60a2                	ld	ra,8(sp)
    800012b8:	6402                	ld	s0,0(sp)
    800012ba:	0141                	addi	sp,sp,16
    800012bc:	8082                	ret

00000000800012be <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012be:	715d                	addi	sp,sp,-80
    800012c0:	e486                	sd	ra,72(sp)
    800012c2:	e0a2                	sd	s0,64(sp)
    800012c4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c6:	03459793          	slli	a5,a1,0x34
    800012ca:	e39d                	bnez	a5,800012f0 <uvmunmap+0x32>
    800012cc:	f84a                	sd	s2,48(sp)
    800012ce:	f44e                	sd	s3,40(sp)
    800012d0:	f052                	sd	s4,32(sp)
    800012d2:	ec56                	sd	s5,24(sp)
    800012d4:	e85a                	sd	s6,16(sp)
    800012d6:	e45e                	sd	s7,8(sp)
    800012d8:	8a2a                	mv	s4,a0
    800012da:	892e                	mv	s2,a1
    800012dc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012de:	0632                	slli	a2,a2,0xc
    800012e0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012e4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012e6:	6b05                	lui	s6,0x1
    800012e8:	0935fb63          	bgeu	a1,s3,8000137e <uvmunmap+0xc0>
    800012ec:	fc26                	sd	s1,56(sp)
    800012ee:	a8a9                	j	80001348 <uvmunmap+0x8a>
    800012f0:	fc26                	sd	s1,56(sp)
    800012f2:	f84a                	sd	s2,48(sp)
    800012f4:	f44e                	sd	s3,40(sp)
    800012f6:	f052                	sd	s4,32(sp)
    800012f8:	ec56                	sd	s5,24(sp)
    800012fa:	e85a                	sd	s6,16(sp)
    800012fc:	e45e                	sd	s7,8(sp)
    panic("uvmunmap: not aligned");
    800012fe:	00007517          	auipc	a0,0x7
    80001302:	de250513          	addi	a0,a0,-542 # 800080e0 <etext+0xe0>
    80001306:	fffff097          	auipc	ra,0xfffff
    8000130a:	25a080e7          	jalr	602(ra) # 80000560 <panic>
      panic("uvmunmap: walk");
    8000130e:	00007517          	auipc	a0,0x7
    80001312:	dea50513          	addi	a0,a0,-534 # 800080f8 <etext+0xf8>
    80001316:	fffff097          	auipc	ra,0xfffff
    8000131a:	24a080e7          	jalr	586(ra) # 80000560 <panic>
      panic("uvmunmap: not mapped");
    8000131e:	00007517          	auipc	a0,0x7
    80001322:	dea50513          	addi	a0,a0,-534 # 80008108 <etext+0x108>
    80001326:	fffff097          	auipc	ra,0xfffff
    8000132a:	23a080e7          	jalr	570(ra) # 80000560 <panic>
      panic("uvmunmap: not a leaf");
    8000132e:	00007517          	auipc	a0,0x7
    80001332:	df250513          	addi	a0,a0,-526 # 80008120 <etext+0x120>
    80001336:	fffff097          	auipc	ra,0xfffff
    8000133a:	22a080e7          	jalr	554(ra) # 80000560 <panic>
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    8000133e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001342:	995a                	add	s2,s2,s6
    80001344:	03397c63          	bgeu	s2,s3,8000137c <uvmunmap+0xbe>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001348:	4601                	li	a2,0
    8000134a:	85ca                	mv	a1,s2
    8000134c:	8552                	mv	a0,s4
    8000134e:	00000097          	auipc	ra,0x0
    80001352:	cc2080e7          	jalr	-830(ra) # 80001010 <walk>
    80001356:	84aa                	mv	s1,a0
    80001358:	d95d                	beqz	a0,8000130e <uvmunmap+0x50>
    if((*pte & PTE_V) == 0)
    8000135a:	6108                	ld	a0,0(a0)
    8000135c:	00157793          	andi	a5,a0,1
    80001360:	dfdd                	beqz	a5,8000131e <uvmunmap+0x60>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001362:	3ff57793          	andi	a5,a0,1023
    80001366:	fd7784e3          	beq	a5,s7,8000132e <uvmunmap+0x70>
    if(do_free){
    8000136a:	fc0a8ae3          	beqz	s5,8000133e <uvmunmap+0x80>
      uint64 pa = PTE2PA(*pte);
    8000136e:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001370:	0532                	slli	a0,a0,0xc
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	6d8080e7          	jalr	1752(ra) # 80000a4a <kfree>
    8000137a:	b7d1                	j	8000133e <uvmunmap+0x80>
    8000137c:	74e2                	ld	s1,56(sp)
    8000137e:	7942                	ld	s2,48(sp)
    80001380:	79a2                	ld	s3,40(sp)
    80001382:	7a02                	ld	s4,32(sp)
    80001384:	6ae2                	ld	s5,24(sp)
    80001386:	6b42                	ld	s6,16(sp)
    80001388:	6ba2                	ld	s7,8(sp)
  }
}
    8000138a:	60a6                	ld	ra,72(sp)
    8000138c:	6406                	ld	s0,64(sp)
    8000138e:	6161                	addi	sp,sp,80
    80001390:	8082                	ret

0000000080001392 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001392:	1101                	addi	sp,sp,-32
    80001394:	ec06                	sd	ra,24(sp)
    80001396:	e822                	sd	s0,16(sp)
    80001398:	e426                	sd	s1,8(sp)
    8000139a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000139c:	fffff097          	auipc	ra,0xfffff
    800013a0:	7ac080e7          	jalr	1964(ra) # 80000b48 <kalloc>
    800013a4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013a6:	c519                	beqz	a0,800013b4 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	988080e7          	jalr	-1656(ra) # 80000d34 <memset>
  return pagetable;
}
    800013b4:	8526                	mv	a0,s1
    800013b6:	60e2                	ld	ra,24(sp)
    800013b8:	6442                	ld	s0,16(sp)
    800013ba:	64a2                	ld	s1,8(sp)
    800013bc:	6105                	addi	sp,sp,32
    800013be:	8082                	ret

00000000800013c0 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c0:	7179                	addi	sp,sp,-48
    800013c2:	f406                	sd	ra,40(sp)
    800013c4:	f022                	sd	s0,32(sp)
    800013c6:	ec26                	sd	s1,24(sp)
    800013c8:	e84a                	sd	s2,16(sp)
    800013ca:	e44e                	sd	s3,8(sp)
    800013cc:	e052                	sd	s4,0(sp)
    800013ce:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d0:	6785                	lui	a5,0x1
    800013d2:	04f67863          	bgeu	a2,a5,80001422 <uvmfirst+0x62>
    800013d6:	8a2a                	mv	s4,a0
    800013d8:	89ae                	mv	s3,a1
    800013da:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	76c080e7          	jalr	1900(ra) # 80000b48 <kalloc>
    800013e4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013e6:	6605                	lui	a2,0x1
    800013e8:	4581                	li	a1,0
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	94a080e7          	jalr	-1718(ra) # 80000d34 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013f2:	4779                	li	a4,30
    800013f4:	86ca                	mv	a3,s2
    800013f6:	6605                	lui	a2,0x1
    800013f8:	4581                	li	a1,0
    800013fa:	8552                	mv	a0,s4
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	cfc080e7          	jalr	-772(ra) # 800010f8 <mappages>
  memmove(mem, src, sz);
    80001404:	8626                	mv	a2,s1
    80001406:	85ce                	mv	a1,s3
    80001408:	854a                	mv	a0,s2
    8000140a:	00000097          	auipc	ra,0x0
    8000140e:	986080e7          	jalr	-1658(ra) # 80000d90 <memmove>
}
    80001412:	70a2                	ld	ra,40(sp)
    80001414:	7402                	ld	s0,32(sp)
    80001416:	64e2                	ld	s1,24(sp)
    80001418:	6942                	ld	s2,16(sp)
    8000141a:	69a2                	ld	s3,8(sp)
    8000141c:	6a02                	ld	s4,0(sp)
    8000141e:	6145                	addi	sp,sp,48
    80001420:	8082                	ret
    panic("uvmfirst: more than a page");
    80001422:	00007517          	auipc	a0,0x7
    80001426:	d1650513          	addi	a0,a0,-746 # 80008138 <etext+0x138>
    8000142a:	fffff097          	auipc	ra,0xfffff
    8000142e:	136080e7          	jalr	310(ra) # 80000560 <panic>

0000000080001432 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001432:	1101                	addi	sp,sp,-32
    80001434:	ec06                	sd	ra,24(sp)
    80001436:	e822                	sd	s0,16(sp)
    80001438:	e426                	sd	s1,8(sp)
    8000143a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000143c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000143e:	00b67d63          	bgeu	a2,a1,80001458 <uvmdealloc+0x26>
    80001442:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001444:	6785                	lui	a5,0x1
    80001446:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001448:	00f60733          	add	a4,a2,a5
    8000144c:	76fd                	lui	a3,0xfffff
    8000144e:	8f75                	and	a4,a4,a3
    80001450:	97ae                	add	a5,a5,a1
    80001452:	8ff5                	and	a5,a5,a3
    80001454:	00f76863          	bltu	a4,a5,80001464 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001458:	8526                	mv	a0,s1
    8000145a:	60e2                	ld	ra,24(sp)
    8000145c:	6442                	ld	s0,16(sp)
    8000145e:	64a2                	ld	s1,8(sp)
    80001460:	6105                	addi	sp,sp,32
    80001462:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001464:	8f99                	sub	a5,a5,a4
    80001466:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001468:	4685                	li	a3,1
    8000146a:	0007861b          	sext.w	a2,a5
    8000146e:	85ba                	mv	a1,a4
    80001470:	00000097          	auipc	ra,0x0
    80001474:	e4e080e7          	jalr	-434(ra) # 800012be <uvmunmap>
    80001478:	b7c5                	j	80001458 <uvmdealloc+0x26>

000000008000147a <uvmalloc>:
  if(newsz < oldsz)
    8000147a:	0ab66b63          	bltu	a2,a1,80001530 <uvmalloc+0xb6>
{
    8000147e:	7139                	addi	sp,sp,-64
    80001480:	fc06                	sd	ra,56(sp)
    80001482:	f822                	sd	s0,48(sp)
    80001484:	ec4e                	sd	s3,24(sp)
    80001486:	e852                	sd	s4,16(sp)
    80001488:	e456                	sd	s5,8(sp)
    8000148a:	0080                	addi	s0,sp,64
    8000148c:	8aaa                	mv	s5,a0
    8000148e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001490:	6785                	lui	a5,0x1
    80001492:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001494:	95be                	add	a1,a1,a5
    80001496:	77fd                	lui	a5,0xfffff
    80001498:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000149c:	08c9fc63          	bgeu	s3,a2,80001534 <uvmalloc+0xba>
    800014a0:	f426                	sd	s1,40(sp)
    800014a2:	f04a                	sd	s2,32(sp)
    800014a4:	e05a                	sd	s6,0(sp)
    800014a6:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a8:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800014ac:	fffff097          	auipc	ra,0xfffff
    800014b0:	69c080e7          	jalr	1692(ra) # 80000b48 <kalloc>
    800014b4:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b6:	c915                	beqz	a0,800014ea <uvmalloc+0x70>
    memset(mem, 0, PGSIZE);
    800014b8:	6605                	lui	a2,0x1
    800014ba:	4581                	li	a1,0
    800014bc:	00000097          	auipc	ra,0x0
    800014c0:	878080e7          	jalr	-1928(ra) # 80000d34 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014c4:	875a                	mv	a4,s6
    800014c6:	86a6                	mv	a3,s1
    800014c8:	6605                	lui	a2,0x1
    800014ca:	85ca                	mv	a1,s2
    800014cc:	8556                	mv	a0,s5
    800014ce:	00000097          	auipc	ra,0x0
    800014d2:	c2a080e7          	jalr	-982(ra) # 800010f8 <mappages>
    800014d6:	ed05                	bnez	a0,8000150e <uvmalloc+0x94>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d8:	6785                	lui	a5,0x1
    800014da:	993e                	add	s2,s2,a5
    800014dc:	fd4968e3          	bltu	s2,s4,800014ac <uvmalloc+0x32>
  return newsz;
    800014e0:	8552                	mv	a0,s4
    800014e2:	74a2                	ld	s1,40(sp)
    800014e4:	7902                	ld	s2,32(sp)
    800014e6:	6b02                	ld	s6,0(sp)
    800014e8:	a821                	j	80001500 <uvmalloc+0x86>
      uvmdealloc(pagetable, a, oldsz);
    800014ea:	864e                	mv	a2,s3
    800014ec:	85ca                	mv	a1,s2
    800014ee:	8556                	mv	a0,s5
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f42080e7          	jalr	-190(ra) # 80001432 <uvmdealloc>
      return 0;
    800014f8:	4501                	li	a0,0
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	6b02                	ld	s6,0(sp)
}
    80001500:	70e2                	ld	ra,56(sp)
    80001502:	7442                	ld	s0,48(sp)
    80001504:	69e2                	ld	s3,24(sp)
    80001506:	6a42                	ld	s4,16(sp)
    80001508:	6aa2                	ld	s5,8(sp)
    8000150a:	6121                	addi	sp,sp,64
    8000150c:	8082                	ret
      kfree(mem);
    8000150e:	8526                	mv	a0,s1
    80001510:	fffff097          	auipc	ra,0xfffff
    80001514:	53a080e7          	jalr	1338(ra) # 80000a4a <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001518:	864e                	mv	a2,s3
    8000151a:	85ca                	mv	a1,s2
    8000151c:	8556                	mv	a0,s5
    8000151e:	00000097          	auipc	ra,0x0
    80001522:	f14080e7          	jalr	-236(ra) # 80001432 <uvmdealloc>
      return 0;
    80001526:	4501                	li	a0,0
    80001528:	74a2                	ld	s1,40(sp)
    8000152a:	7902                	ld	s2,32(sp)
    8000152c:	6b02                	ld	s6,0(sp)
    8000152e:	bfc9                	j	80001500 <uvmalloc+0x86>
    return oldsz;
    80001530:	852e                	mv	a0,a1
}
    80001532:	8082                	ret
  return newsz;
    80001534:	8532                	mv	a0,a2
    80001536:	b7e9                	j	80001500 <uvmalloc+0x86>

0000000080001538 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001538:	7179                	addi	sp,sp,-48
    8000153a:	f406                	sd	ra,40(sp)
    8000153c:	f022                	sd	s0,32(sp)
    8000153e:	ec26                	sd	s1,24(sp)
    80001540:	e84a                	sd	s2,16(sp)
    80001542:	e44e                	sd	s3,8(sp)
    80001544:	e052                	sd	s4,0(sp)
    80001546:	1800                	addi	s0,sp,48
    80001548:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000154a:	84aa                	mv	s1,a0
    8000154c:	6905                	lui	s2,0x1
    8000154e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001550:	4985                	li	s3,1
    80001552:	a829                	j	8000156c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001554:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001556:	00c79513          	slli	a0,a5,0xc
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	fde080e7          	jalr	-34(ra) # 80001538 <freewalk>
      pagetable[i] = 0;
    80001562:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001566:	04a1                	addi	s1,s1,8
    80001568:	03248163          	beq	s1,s2,8000158a <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000156c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000156e:	00f7f713          	andi	a4,a5,15
    80001572:	ff3701e3          	beq	a4,s3,80001554 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001576:	8b85                	andi	a5,a5,1
    80001578:	d7fd                	beqz	a5,80001566 <freewalk+0x2e>
      panic("freewalk: leaf");
    8000157a:	00007517          	auipc	a0,0x7
    8000157e:	bde50513          	addi	a0,a0,-1058 # 80008158 <etext+0x158>
    80001582:	fffff097          	auipc	ra,0xfffff
    80001586:	fde080e7          	jalr	-34(ra) # 80000560 <panic>
    }
  }
  kfree((void*)pagetable);
    8000158a:	8552                	mv	a0,s4
    8000158c:	fffff097          	auipc	ra,0xfffff
    80001590:	4be080e7          	jalr	1214(ra) # 80000a4a <kfree>
}
    80001594:	70a2                	ld	ra,40(sp)
    80001596:	7402                	ld	s0,32(sp)
    80001598:	64e2                	ld	s1,24(sp)
    8000159a:	6942                	ld	s2,16(sp)
    8000159c:	69a2                	ld	s3,8(sp)
    8000159e:	6a02                	ld	s4,0(sp)
    800015a0:	6145                	addi	sp,sp,48
    800015a2:	8082                	ret

00000000800015a4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015a4:	1101                	addi	sp,sp,-32
    800015a6:	ec06                	sd	ra,24(sp)
    800015a8:	e822                	sd	s0,16(sp)
    800015aa:	e426                	sd	s1,8(sp)
    800015ac:	1000                	addi	s0,sp,32
    800015ae:	84aa                	mv	s1,a0
  if(sz > 0)
    800015b0:	e999                	bnez	a1,800015c6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015b2:	8526                	mv	a0,s1
    800015b4:	00000097          	auipc	ra,0x0
    800015b8:	f84080e7          	jalr	-124(ra) # 80001538 <freewalk>
}
    800015bc:	60e2                	ld	ra,24(sp)
    800015be:	6442                	ld	s0,16(sp)
    800015c0:	64a2                	ld	s1,8(sp)
    800015c2:	6105                	addi	sp,sp,32
    800015c4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015c6:	6785                	lui	a5,0x1
    800015c8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015ca:	95be                	add	a1,a1,a5
    800015cc:	4685                	li	a3,1
    800015ce:	00c5d613          	srli	a2,a1,0xc
    800015d2:	4581                	li	a1,0
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	cea080e7          	jalr	-790(ra) # 800012be <uvmunmap>
    800015dc:	bfd9                	j	800015b2 <uvmfree+0xe>

00000000800015de <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015de:	c679                	beqz	a2,800016ac <uvmcopy+0xce>
{
    800015e0:	715d                	addi	sp,sp,-80
    800015e2:	e486                	sd	ra,72(sp)
    800015e4:	e0a2                	sd	s0,64(sp)
    800015e6:	fc26                	sd	s1,56(sp)
    800015e8:	f84a                	sd	s2,48(sp)
    800015ea:	f44e                	sd	s3,40(sp)
    800015ec:	f052                	sd	s4,32(sp)
    800015ee:	ec56                	sd	s5,24(sp)
    800015f0:	e85a                	sd	s6,16(sp)
    800015f2:	e45e                	sd	s7,8(sp)
    800015f4:	0880                	addi	s0,sp,80
    800015f6:	8b2a                	mv	s6,a0
    800015f8:	8aae                	mv	s5,a1
    800015fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015fc:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015fe:	4601                	li	a2,0
    80001600:	85ce                	mv	a1,s3
    80001602:	855a                	mv	a0,s6
    80001604:	00000097          	auipc	ra,0x0
    80001608:	a0c080e7          	jalr	-1524(ra) # 80001010 <walk>
    8000160c:	c531                	beqz	a0,80001658 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000160e:	6118                	ld	a4,0(a0)
    80001610:	00177793          	andi	a5,a4,1
    80001614:	cbb1                	beqz	a5,80001668 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001616:	00a75593          	srli	a1,a4,0xa
    8000161a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000161e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001622:	fffff097          	auipc	ra,0xfffff
    80001626:	526080e7          	jalr	1318(ra) # 80000b48 <kalloc>
    8000162a:	892a                	mv	s2,a0
    8000162c:	c939                	beqz	a0,80001682 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000162e:	6605                	lui	a2,0x1
    80001630:	85de                	mv	a1,s7
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	75e080e7          	jalr	1886(ra) # 80000d90 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000163a:	8726                	mv	a4,s1
    8000163c:	86ca                	mv	a3,s2
    8000163e:	6605                	lui	a2,0x1
    80001640:	85ce                	mv	a1,s3
    80001642:	8556                	mv	a0,s5
    80001644:	00000097          	auipc	ra,0x0
    80001648:	ab4080e7          	jalr	-1356(ra) # 800010f8 <mappages>
    8000164c:	e515                	bnez	a0,80001678 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000164e:	6785                	lui	a5,0x1
    80001650:	99be                	add	s3,s3,a5
    80001652:	fb49e6e3          	bltu	s3,s4,800015fe <uvmcopy+0x20>
    80001656:	a081                	j	80001696 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b1050513          	addi	a0,a0,-1264 # 80008168 <etext+0x168>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	f00080e7          	jalr	-256(ra) # 80000560 <panic>
      panic("uvmcopy: page not present");
    80001668:	00007517          	auipc	a0,0x7
    8000166c:	b2050513          	addi	a0,a0,-1248 # 80008188 <etext+0x188>
    80001670:	fffff097          	auipc	ra,0xfffff
    80001674:	ef0080e7          	jalr	-272(ra) # 80000560 <panic>
      kfree(mem);
    80001678:	854a                	mv	a0,s2
    8000167a:	fffff097          	auipc	ra,0xfffff
    8000167e:	3d0080e7          	jalr	976(ra) # 80000a4a <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001682:	4685                	li	a3,1
    80001684:	00c9d613          	srli	a2,s3,0xc
    80001688:	4581                	li	a1,0
    8000168a:	8556                	mv	a0,s5
    8000168c:	00000097          	auipc	ra,0x0
    80001690:	c32080e7          	jalr	-974(ra) # 800012be <uvmunmap>
  return -1;
    80001694:	557d                	li	a0,-1
}
    80001696:	60a6                	ld	ra,72(sp)
    80001698:	6406                	ld	s0,64(sp)
    8000169a:	74e2                	ld	s1,56(sp)
    8000169c:	7942                	ld	s2,48(sp)
    8000169e:	79a2                	ld	s3,40(sp)
    800016a0:	7a02                	ld	s4,32(sp)
    800016a2:	6ae2                	ld	s5,24(sp)
    800016a4:	6b42                	ld	s6,16(sp)
    800016a6:	6ba2                	ld	s7,8(sp)
    800016a8:	6161                	addi	sp,sp,80
    800016aa:	8082                	ret
  return 0;
    800016ac:	4501                	li	a0,0
}
    800016ae:	8082                	ret

00000000800016b0 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016b0:	1141                	addi	sp,sp,-16
    800016b2:	e406                	sd	ra,8(sp)
    800016b4:	e022                	sd	s0,0(sp)
    800016b6:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016b8:	4601                	li	a2,0
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	956080e7          	jalr	-1706(ra) # 80001010 <walk>
  if(pte == 0)
    800016c2:	c901                	beqz	a0,800016d2 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016c4:	611c                	ld	a5,0(a0)
    800016c6:	9bbd                	andi	a5,a5,-17
    800016c8:	e11c                	sd	a5,0(a0)
}
    800016ca:	60a2                	ld	ra,8(sp)
    800016cc:	6402                	ld	s0,0(sp)
    800016ce:	0141                	addi	sp,sp,16
    800016d0:	8082                	ret
    panic("uvmclear");
    800016d2:	00007517          	auipc	a0,0x7
    800016d6:	ad650513          	addi	a0,a0,-1322 # 800081a8 <etext+0x1a8>
    800016da:	fffff097          	auipc	ra,0xfffff
    800016de:	e86080e7          	jalr	-378(ra) # 80000560 <panic>

00000000800016e2 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016e2:	c6bd                	beqz	a3,80001750 <copyout+0x6e>
{
    800016e4:	715d                	addi	sp,sp,-80
    800016e6:	e486                	sd	ra,72(sp)
    800016e8:	e0a2                	sd	s0,64(sp)
    800016ea:	fc26                	sd	s1,56(sp)
    800016ec:	f84a                	sd	s2,48(sp)
    800016ee:	f44e                	sd	s3,40(sp)
    800016f0:	f052                	sd	s4,32(sp)
    800016f2:	ec56                	sd	s5,24(sp)
    800016f4:	e85a                	sd	s6,16(sp)
    800016f6:	e45e                	sd	s7,8(sp)
    800016f8:	e062                	sd	s8,0(sp)
    800016fa:	0880                	addi	s0,sp,80
    800016fc:	8b2a                	mv	s6,a0
    800016fe:	8c2e                	mv	s8,a1
    80001700:	8a32                	mv	s4,a2
    80001702:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001704:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001706:	6a85                	lui	s5,0x1
    80001708:	a015                	j	8000172c <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000170a:	9562                	add	a0,a0,s8
    8000170c:	0004861b          	sext.w	a2,s1
    80001710:	85d2                	mv	a1,s4
    80001712:	41250533          	sub	a0,a0,s2
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	67a080e7          	jalr	1658(ra) # 80000d90 <memmove>

    len -= n;
    8000171e:	409989b3          	sub	s3,s3,s1
    src += n;
    80001722:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001724:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001728:	02098263          	beqz	s3,8000174c <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    8000172c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001730:	85ca                	mv	a1,s2
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	982080e7          	jalr	-1662(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    8000173c:	cd01                	beqz	a0,80001754 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    8000173e:	418904b3          	sub	s1,s2,s8
    80001742:	94d6                	add	s1,s1,s5
    if(n > len)
    80001744:	fc99f3e3          	bgeu	s3,s1,8000170a <copyout+0x28>
    80001748:	84ce                	mv	s1,s3
    8000174a:	b7c1                	j	8000170a <copyout+0x28>
  }
  return 0;
    8000174c:	4501                	li	a0,0
    8000174e:	a021                	j	80001756 <copyout+0x74>
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret
      return -1;
    80001754:	557d                	li	a0,-1
}
    80001756:	60a6                	ld	ra,72(sp)
    80001758:	6406                	ld	s0,64(sp)
    8000175a:	74e2                	ld	s1,56(sp)
    8000175c:	7942                	ld	s2,48(sp)
    8000175e:	79a2                	ld	s3,40(sp)
    80001760:	7a02                	ld	s4,32(sp)
    80001762:	6ae2                	ld	s5,24(sp)
    80001764:	6b42                	ld	s6,16(sp)
    80001766:	6ba2                	ld	s7,8(sp)
    80001768:	6c02                	ld	s8,0(sp)
    8000176a:	6161                	addi	sp,sp,80
    8000176c:	8082                	ret

000000008000176e <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000176e:	caa5                	beqz	a3,800017de <copyin+0x70>
{
    80001770:	715d                	addi	sp,sp,-80
    80001772:	e486                	sd	ra,72(sp)
    80001774:	e0a2                	sd	s0,64(sp)
    80001776:	fc26                	sd	s1,56(sp)
    80001778:	f84a                	sd	s2,48(sp)
    8000177a:	f44e                	sd	s3,40(sp)
    8000177c:	f052                	sd	s4,32(sp)
    8000177e:	ec56                	sd	s5,24(sp)
    80001780:	e85a                	sd	s6,16(sp)
    80001782:	e45e                	sd	s7,8(sp)
    80001784:	e062                	sd	s8,0(sp)
    80001786:	0880                	addi	s0,sp,80
    80001788:	8b2a                	mv	s6,a0
    8000178a:	8a2e                	mv	s4,a1
    8000178c:	8c32                	mv	s8,a2
    8000178e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001790:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001792:	6a85                	lui	s5,0x1
    80001794:	a01d                	j	800017ba <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001796:	018505b3          	add	a1,a0,s8
    8000179a:	0004861b          	sext.w	a2,s1
    8000179e:	412585b3          	sub	a1,a1,s2
    800017a2:	8552                	mv	a0,s4
    800017a4:	fffff097          	auipc	ra,0xfffff
    800017a8:	5ec080e7          	jalr	1516(ra) # 80000d90 <memmove>

    len -= n;
    800017ac:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017b0:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017b2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017b6:	02098263          	beqz	s3,800017da <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800017ba:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017be:	85ca                	mv	a1,s2
    800017c0:	855a                	mv	a0,s6
    800017c2:	00000097          	auipc	ra,0x0
    800017c6:	8f4080e7          	jalr	-1804(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    800017ca:	cd01                	beqz	a0,800017e2 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017cc:	418904b3          	sub	s1,s2,s8
    800017d0:	94d6                	add	s1,s1,s5
    if(n > len)
    800017d2:	fc99f2e3          	bgeu	s3,s1,80001796 <copyin+0x28>
    800017d6:	84ce                	mv	s1,s3
    800017d8:	bf7d                	j	80001796 <copyin+0x28>
  }
  return 0;
    800017da:	4501                	li	a0,0
    800017dc:	a021                	j	800017e4 <copyin+0x76>
    800017de:	4501                	li	a0,0
}
    800017e0:	8082                	ret
      return -1;
    800017e2:	557d                	li	a0,-1
}
    800017e4:	60a6                	ld	ra,72(sp)
    800017e6:	6406                	ld	s0,64(sp)
    800017e8:	74e2                	ld	s1,56(sp)
    800017ea:	7942                	ld	s2,48(sp)
    800017ec:	79a2                	ld	s3,40(sp)
    800017ee:	7a02                	ld	s4,32(sp)
    800017f0:	6ae2                	ld	s5,24(sp)
    800017f2:	6b42                	ld	s6,16(sp)
    800017f4:	6ba2                	ld	s7,8(sp)
    800017f6:	6c02                	ld	s8,0(sp)
    800017f8:	6161                	addi	sp,sp,80
    800017fa:	8082                	ret

00000000800017fc <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017fc:	cacd                	beqz	a3,800018ae <copyinstr+0xb2>
{
    800017fe:	715d                	addi	sp,sp,-80
    80001800:	e486                	sd	ra,72(sp)
    80001802:	e0a2                	sd	s0,64(sp)
    80001804:	fc26                	sd	s1,56(sp)
    80001806:	f84a                	sd	s2,48(sp)
    80001808:	f44e                	sd	s3,40(sp)
    8000180a:	f052                	sd	s4,32(sp)
    8000180c:	ec56                	sd	s5,24(sp)
    8000180e:	e85a                	sd	s6,16(sp)
    80001810:	e45e                	sd	s7,8(sp)
    80001812:	0880                	addi	s0,sp,80
    80001814:	8a2a                	mv	s4,a0
    80001816:	8b2e                	mv	s6,a1
    80001818:	8bb2                	mv	s7,a2
    8000181a:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    8000181c:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000181e:	6985                	lui	s3,0x1
    80001820:	a825                	j	80001858 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001822:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001826:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001828:	37fd                	addiw	a5,a5,-1
    8000182a:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    8000182e:	60a6                	ld	ra,72(sp)
    80001830:	6406                	ld	s0,64(sp)
    80001832:	74e2                	ld	s1,56(sp)
    80001834:	7942                	ld	s2,48(sp)
    80001836:	79a2                	ld	s3,40(sp)
    80001838:	7a02                	ld	s4,32(sp)
    8000183a:	6ae2                	ld	s5,24(sp)
    8000183c:	6b42                	ld	s6,16(sp)
    8000183e:	6ba2                	ld	s7,8(sp)
    80001840:	6161                	addi	sp,sp,80
    80001842:	8082                	ret
    80001844:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    80001848:	9742                	add	a4,a4,a6
      --max;
    8000184a:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    8000184e:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    80001852:	04e58663          	beq	a1,a4,8000189e <copyinstr+0xa2>
{
    80001856:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    80001858:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    8000185c:	85a6                	mv	a1,s1
    8000185e:	8552                	mv	a0,s4
    80001860:	00000097          	auipc	ra,0x0
    80001864:	856080e7          	jalr	-1962(ra) # 800010b6 <walkaddr>
    if(pa0 == 0)
    80001868:	cd0d                	beqz	a0,800018a2 <copyinstr+0xa6>
    n = PGSIZE - (srcva - va0);
    8000186a:	417486b3          	sub	a3,s1,s7
    8000186e:	96ce                	add	a3,a3,s3
    if(n > max)
    80001870:	00d97363          	bgeu	s2,a3,80001876 <copyinstr+0x7a>
    80001874:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    80001876:	955e                	add	a0,a0,s7
    80001878:	8d05                	sub	a0,a0,s1
    while(n > 0){
    8000187a:	c695                	beqz	a3,800018a6 <copyinstr+0xaa>
    8000187c:	87da                	mv	a5,s6
    8000187e:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001880:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001884:	96da                	add	a3,a3,s6
    80001886:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001888:	00f60733          	add	a4,a2,a5
    8000188c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd6eb0>
    80001890:	db49                	beqz	a4,80001822 <copyinstr+0x26>
        *dst = *p;
    80001892:	00e78023          	sb	a4,0(a5)
      dst++;
    80001896:	0785                	addi	a5,a5,1
    while(n > 0){
    80001898:	fed797e3          	bne	a5,a3,80001886 <copyinstr+0x8a>
    8000189c:	b765                	j	80001844 <copyinstr+0x48>
    8000189e:	4781                	li	a5,0
    800018a0:	b761                	j	80001828 <copyinstr+0x2c>
      return -1;
    800018a2:	557d                	li	a0,-1
    800018a4:	b769                	j	8000182e <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    800018a6:	6b85                	lui	s7,0x1
    800018a8:	9ba6                	add	s7,s7,s1
    800018aa:	87da                	mv	a5,s6
    800018ac:	b76d                	j	80001856 <copyinstr+0x5a>
  int got_null = 0;
    800018ae:	4781                	li	a5,0
  if(got_null){
    800018b0:	37fd                	addiw	a5,a5,-1
    800018b2:	0007851b          	sext.w	a0,a5
}
    800018b6:	8082                	ret

00000000800018b8 <random_gene>:


unsigned long randstate = 1;

unsigned int random_gene()
{
    800018b8:	1141                	addi	sp,sp,-16
    800018ba:	e422                	sd	s0,8(sp)
    800018bc:	0800                	addi	s0,sp,16
  randstate = randstate * 1664525 + 1013904223;
    800018be:	0000a717          	auipc	a4,0xa
    800018c2:	b2a70713          	addi	a4,a4,-1238 # 8000b3e8 <randstate>
    800018c6:	6308                	ld	a0,0(a4)
    800018c8:	001967b7          	lui	a5,0x196
    800018cc:	60d78793          	addi	a5,a5,1549 # 19660d <_entry-0x7fe699f3>
    800018d0:	02f50533          	mul	a0,a0,a5
    800018d4:	3c6ef7b7          	lui	a5,0x3c6ef
    800018d8:	35f78793          	addi	a5,a5,863 # 3c6ef35f <_entry-0x43910ca1>
    800018dc:	953e                	add	a0,a0,a5
    800018de:	e308                	sd	a0,0(a4)
  return (randstate % 0x7FFFFFFF);
    800018e0:	800007b7          	lui	a5,0x80000
    800018e4:	fff7c793          	not	a5,a5
    800018e8:	02f57533          	remu	a0,a0,a5
}
    800018ec:	2501                	sext.w	a0,a0
    800018ee:	6422                	ld	s0,8(sp)
    800018f0:	0141                	addi	sp,sp,16
    800018f2:	8082                	ret

00000000800018f4 <initialize>:

mlfq_que mlfq[totalQs];



void initialize(){
    800018f4:	1141                	addi	sp,sp,-16
    800018f6:	e422                	sd	s0,8(sp)
    800018f8:	0800                	addi	s0,sp,16
  mlfq[0].time_slice = 1;
    800018fa:	00012797          	auipc	a5,0x12
    800018fe:	23678793          	addi	a5,a5,566 # 80013b30 <mlfq>
    80001902:	4705                	li	a4,1
    80001904:	20e7a423          	sw	a4,520(a5)
  mlfq[1].time_slice = 4;
    80001908:	4711                	li	a4,4
    8000190a:	40e7ac23          	sw	a4,1048(a5)
  mlfq[2].time_slice = 8;
    8000190e:	4721                	li	a4,8
    80001910:	62e7a423          	sw	a4,1576(a5)
  mlfq[3].time_slice = 16;
    80001914:	47c1                	li	a5,16
    80001916:	00013717          	auipc	a4,0x13
    8000191a:	a4f72923          	sw	a5,-1454(a4) # 80014368 <mlfq+0x838>

  for(int i=0;i<totalQs;i++){
    8000191e:	00012717          	auipc	a4,0x12
    80001922:	41270713          	addi	a4,a4,1042 # 80013d30 <mlfq+0x200>
    80001926:	00013697          	auipc	a3,0x13
    8000192a:	c4a68693          	addi	a3,a3,-950 # 80014570 <proc+0x200>
    mlfq[i].head_ptr = 0;
    8000192e:	00072023          	sw	zero,0(a4)
    mlfq[i].tail_ptr = 0;
    80001932:	00072223          	sw	zero,4(a4)
    for(int j=0;j<NPROC;j++){
    80001936:	e0070793          	addi	a5,a4,-512
      mlfq[i].process[j] = 0;
    8000193a:	0007b023          	sd	zero,0(a5)
    for(int j=0;j<NPROC;j++){
    8000193e:	07a1                	addi	a5,a5,8
    80001940:	fee79de3          	bne	a5,a4,8000193a <initialize+0x46>
  for(int i=0;i<totalQs;i++){
    80001944:	21070713          	addi	a4,a4,528
    80001948:	fed713e3          	bne	a4,a3,8000192e <initialize+0x3a>
    }
  }
  
}
    8000194c:	6422                	ld	s0,8(sp)
    8000194e:	0141                	addi	sp,sp,16
    80001950:	8082                	ret

0000000080001952 <enque_mlfq>:


/// push operation  // can add % operation
void enque_mlfq(struct proc* p,int que_no){
    80001952:	1141                	addi	sp,sp,-16
    80001954:	e422                	sd	s0,8(sp)
    80001956:	0800                	addi	s0,sp,16
  // printf("-----hello\n");
  if(mlfq[que_no].tail_ptr < NPROC){
    80001958:	00559793          	slli	a5,a1,0x5
    8000195c:	97ae                	add	a5,a5,a1
    8000195e:	0792                	slli	a5,a5,0x4
    80001960:	00012717          	auipc	a4,0x12
    80001964:	1d070713          	addi	a4,a4,464 # 80013b30 <mlfq>
    80001968:	97ba                	add	a5,a5,a4
    8000196a:	2047a703          	lw	a4,516(a5)
    8000196e:	03f00793          	li	a5,63
    80001972:	02e7ca63          	blt	a5,a4,800019a6 <enque_mlfq+0x54>
    int n = mlfq[que_no].tail_ptr;
    mlfq[que_no].process[n] = p;
    80001976:	00012617          	auipc	a2,0x12
    8000197a:	1ba60613          	addi	a2,a2,442 # 80013b30 <mlfq>
    8000197e:	00559693          	slli	a3,a1,0x5
    80001982:	00b687b3          	add	a5,a3,a1
    80001986:	0786                	slli	a5,a5,0x1
    80001988:	97ba                	add	a5,a5,a4
    8000198a:	078e                	slli	a5,a5,0x3
    8000198c:	97b2                	add	a5,a5,a2
    8000198e:	e388                	sd	a0,0(a5)
    mlfq[que_no].tail_ptr++;
    80001990:	96ae                	add	a3,a3,a1
    80001992:	0692                	slli	a3,a3,0x4
    80001994:	9636                	add	a2,a2,a3
    80001996:	2705                	addiw	a4,a4,1
    80001998:	20e62223          	sw	a4,516(a2)

    p->is_PQue = 1;
    8000199c:	4785                	li	a5,1
    8000199e:	20f52c23          	sw	a5,536(a0)
    p->CQue_no = que_no;
    800019a2:	20b52a23          	sw	a1,532(a0)
  }
}
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <add_front_mlfq>:

void add_front_mlfq(struct proc* p,int que_no){
  // mlfq[que_no].tail_ptr ++;
  if(mlfq[que_no].tail_ptr  < NPROC){
    800019ac:	00559793          	slli	a5,a1,0x5
    800019b0:	97ae                	add	a5,a5,a1
    800019b2:	0792                	slli	a5,a5,0x4
    800019b4:	00012717          	auipc	a4,0x12
    800019b8:	17c70713          	addi	a4,a4,380 # 80013b30 <mlfq>
    800019bc:	97ba                	add	a5,a5,a4
    800019be:	2047a603          	lw	a2,516(a5)
    800019c2:	03f00793          	li	a5,63
    800019c6:	04c7c563          	blt	a5,a2,80001a10 <add_front_mlfq+0x64>

  for(int i = mlfq[que_no].tail_ptr ; i > 0 ; i-- ){
    800019ca:	02c05063          	blez	a2,800019ea <add_front_mlfq+0x3e>
    800019ce:	00559793          	slli	a5,a1,0x5
    800019d2:	97ae                	add	a5,a5,a1
    800019d4:	0786                	slli	a5,a5,0x1
    800019d6:	97b2                	add	a5,a5,a2
    800019d8:	078e                	slli	a5,a5,0x3
    800019da:	97ba                	add	a5,a5,a4
    800019dc:	8732                	mv	a4,a2
    mlfq[que_no].process[i] = mlfq[que_no].process[i-1];    
    800019de:	377d                	addiw	a4,a4,-1
    800019e0:	ff87b683          	ld	a3,-8(a5)
    800019e4:	e394                	sd	a3,0(a5)
  for(int i = mlfq[que_no].tail_ptr ; i > 0 ; i-- ){
    800019e6:	17e1                	addi	a5,a5,-8
    800019e8:	fb7d                	bnez	a4,800019de <add_front_mlfq+0x32>
  }
   mlfq[que_no].tail_ptr ++;
    800019ea:	00559793          	slli	a5,a1,0x5
    800019ee:	97ae                	add	a5,a5,a1
    800019f0:	0792                	slli	a5,a5,0x4
    800019f2:	00012717          	auipc	a4,0x12
    800019f6:	13e70713          	addi	a4,a4,318 # 80013b30 <mlfq>
    800019fa:	97ba                	add	a5,a5,a4
    800019fc:	2605                	addiw	a2,a2,1
    800019fe:	20c7a223          	sw	a2,516(a5)
   mlfq[que_no].process[0] = p;  
    80001a02:	e388                	sd	a0,0(a5)
  p->CQue_no = que_no;
    80001a04:	20b52a23          	sw	a1,532(a0)
  p->is_PQue = 1;
    80001a08:	4785                	li	a5,1
    80001a0a:	20f52c23          	sw	a5,536(a0)
    80001a0e:	8082                	ret
void add_front_mlfq(struct proc* p,int que_no){
    80001a10:	1141                	addi	sp,sp,-16
    80001a12:	e406                	sd	ra,8(sp)
    80001a14:	e022                	sd	s0,0(sp)
    80001a16:	0800                	addi	s0,sp,16
  
  }else{
    printf("que is full \n");
    80001a18:	00006517          	auipc	a0,0x6
    80001a1c:	7a050513          	addi	a0,a0,1952 # 800081b8 <etext+0x1b8>
    80001a20:	fffff097          	auipc	ra,0xfffff
    80001a24:	b8a080e7          	jalr	-1142(ra) # 800005aa <printf>
  }

}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret

0000000080001a30 <deque_mlfq>:

struct proc* deque_mlfq(int que_no){
  if(mlfq[que_no].tail_ptr > 0){
    80001a30:	00551793          	slli	a5,a0,0x5
    80001a34:	97aa                	add	a5,a5,a0
    80001a36:	0792                	slli	a5,a5,0x4
    80001a38:	00012717          	auipc	a4,0x12
    80001a3c:	0f870713          	addi	a4,a4,248 # 80013b30 <mlfq>
    80001a40:	97ba                	add	a5,a5,a4
    80001a42:	2047a583          	lw	a1,516(a5)
    80001a46:	06b05363          	blez	a1,80001aac <deque_mlfq+0x7c>
    80001a4a:	862a                	mv	a2,a0
     struct proc* p = mlfq[que_no].process[0];
    80001a4c:	00551713          	slli	a4,a0,0x5
    80001a50:	00a706b3          	add	a3,a4,a0
    80001a54:	0692                	slli	a3,a3,0x4
    80001a56:	00012797          	auipc	a5,0x12
    80001a5a:	0da78793          	addi	a5,a5,218 # 80013b30 <mlfq>
    80001a5e:	97b6                	add	a5,a5,a3
    80001a60:	6388                	ld	a0,0(a5)

     mlfq[que_no].process[0] = 0;
    80001a62:	0007b023          	sd	zero,0(a5)
    for(int i=0;i<NPROC-1;i++){
    80001a66:	8736                	mv	a4,a3
    80001a68:	00012697          	auipc	a3,0x12
    80001a6c:	2c068693          	addi	a3,a3,704 # 80013d28 <mlfq+0x1f8>
    80001a70:	96ba                	add	a3,a3,a4
      mlfq[que_no].process[i] = mlfq[que_no].process[i+1];
    80001a72:	6798                	ld	a4,8(a5)
    80001a74:	e398                	sd	a4,0(a5)
    for(int i=0;i<NPROC-1;i++){
    80001a76:	07a1                	addi	a5,a5,8
    80001a78:	fed79de3          	bne	a5,a3,80001a72 <deque_mlfq+0x42>
    }
    mlfq[que_no].process[mlfq[que_no].tail_ptr] = 0;
    80001a7c:	00012697          	auipc	a3,0x12
    80001a80:	0b468693          	addi	a3,a3,180 # 80013b30 <mlfq>
    80001a84:	00561713          	slli	a4,a2,0x5
    80001a88:	00c707b3          	add	a5,a4,a2
    80001a8c:	0786                	slli	a5,a5,0x1
    80001a8e:	97ae                	add	a5,a5,a1
    80001a90:	078e                	slli	a5,a5,0x3
    80001a92:	97b6                	add	a5,a5,a3
    80001a94:	0007b023          	sd	zero,0(a5)
    mlfq[que_no].tail_ptr --;
    80001a98:	00c707b3          	add	a5,a4,a2
    80001a9c:	0792                	slli	a5,a5,0x4
    80001a9e:	96be                	add	a3,a3,a5
    80001aa0:	35fd                	addiw	a1,a1,-1
    80001aa2:	20b6a223          	sw	a1,516(a3)
    p->is_PQue = 0;
    80001aa6:	20052c23          	sw	zero,536(a0)
  printf("Que is empty\n");
  }

  return 0;

}
    80001aaa:	8082                	ret
struct proc* deque_mlfq(int que_no){
    80001aac:	1141                	addi	sp,sp,-16
    80001aae:	e406                	sd	ra,8(sp)
    80001ab0:	e022                	sd	s0,0(sp)
    80001ab2:	0800                	addi	s0,sp,16
  printf("Que is empty\n");
    80001ab4:	00006517          	auipc	a0,0x6
    80001ab8:	71450513          	addi	a0,a0,1812 # 800081c8 <etext+0x1c8>
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	aee080e7          	jalr	-1298(ra) # 800005aa <printf>
  return 0;
    80001ac4:	4501                	li	a0,0
}
    80001ac6:	60a2                	ld	ra,8(sp)
    80001ac8:	6402                	ld	s0,0(sp)
    80001aca:	0141                	addi	sp,sp,16
    80001acc:	8082                	ret

0000000080001ace <remProcess>:

// remove process

void remProcess(int que_no,struct proc*p){
    80001ace:	1141                	addi	sp,sp,-16
    80001ad0:	e422                	sd	s0,8(sp)
    80001ad2:	0800                	addi	s0,sp,16
  for(int i= mlfq[que_no].head_ptr ; i< mlfq[que_no].tail_ptr;i++ ){
    80001ad4:	00551793          	slli	a5,a0,0x5
    80001ad8:	97aa                	add	a5,a5,a0
    80001ada:	0792                	slli	a5,a5,0x4
    80001adc:	00012717          	auipc	a4,0x12
    80001ae0:	05470713          	addi	a4,a4,84 # 80013b30 <mlfq>
    80001ae4:	97ba                	add	a5,a5,a4
    80001ae6:	2007a703          	lw	a4,512(a5)
    80001aea:	2047a683          	lw	a3,516(a5)
    80001aee:	08d75d63          	bge	a4,a3,80001b88 <remProcess+0xba>
    80001af2:	00551813          	slli	a6,a0,0x5
    80001af6:	982a                	add	a6,a6,a0
    80001af8:	0806                	slli	a6,a6,0x1
    80001afa:	010707b3          	add	a5,a4,a6
    80001afe:	078e                	slli	a5,a5,0x3
    80001b00:	00012617          	auipc	a2,0x12
    80001b04:	03060613          	addi	a2,a2,48 # 80013b30 <mlfq>
    80001b08:	97b2                	add	a5,a5,a2
    if(mlfq[que_no].process[i]  == p){
    80001b0a:	6390                	ld	a2,0(a5)
    80001b0c:	00b60763          	beq	a2,a1,80001b1a <remProcess+0x4c>
  for(int i= mlfq[que_no].head_ptr ; i< mlfq[que_no].tail_ptr;i++ ){
    80001b10:	2705                	addiw	a4,a4,1
    80001b12:	07a1                	addi	a5,a5,8
    80001b14:	fed71be3          	bne	a4,a3,80001b0a <remProcess+0x3c>
    80001b18:	a885                	j	80001b88 <remProcess+0xba>

      for(int j=i;j<mlfq[que_no].tail_ptr - 1;j++){
    80001b1a:	fff6889b          	addiw	a7,a3,-1
    80001b1e:	0008879b          	sext.w	a5,a7
    80001b22:	04f75863          	bge	a4,a5,80001b72 <remProcess+0xa4>
    80001b26:	00180613          	addi	a2,a6,1
    80001b2a:	963a                	add	a2,a2,a4
    80001b2c:	060e                	slli	a2,a2,0x3
    80001b2e:	00012797          	auipc	a5,0x12
    80001b32:	00278793          	addi	a5,a5,2 # 80013b30 <mlfq>
    80001b36:	963e                	add	a2,a2,a5
    80001b38:	ffe6879b          	addiw	a5,a3,-2
    80001b3c:	9f99                	subw	a5,a5,a4
    80001b3e:	1782                	slli	a5,a5,0x20
    80001b40:	9381                	srli	a5,a5,0x20
    80001b42:	983a                	add	a6,a6,a4
    80001b44:	97c2                	add	a5,a5,a6
    80001b46:	078e                	slli	a5,a5,0x3
    80001b48:	00012697          	auipc	a3,0x12
    80001b4c:	ff868693          	addi	a3,a3,-8 # 80013b40 <mlfq+0x10>
    80001b50:	97b6                	add	a5,a5,a3
        mlfq[que_no].process[i] = mlfq[que_no].process[j+1];
    80001b52:	00551693          	slli	a3,a0,0x5
    80001b56:	96aa                	add	a3,a3,a0
    80001b58:	0686                	slli	a3,a3,0x1
    80001b5a:	9736                	add	a4,a4,a3
    80001b5c:	070e                	slli	a4,a4,0x3
    80001b5e:	00012697          	auipc	a3,0x12
    80001b62:	fd268693          	addi	a3,a3,-46 # 80013b30 <mlfq>
    80001b66:	96ba                	add	a3,a3,a4
    80001b68:	6218                	ld	a4,0(a2)
    80001b6a:	e298                	sd	a4,0(a3)
      for(int j=i;j<mlfq[que_no].tail_ptr - 1;j++){
    80001b6c:	0621                	addi	a2,a2,8
    80001b6e:	fef61de3          	bne	a2,a5,80001b68 <remProcess+0x9a>
      }

      mlfq[que_no].tail_ptr -- ;
    80001b72:	00551793          	slli	a5,a0,0x5
    80001b76:	97aa                	add	a5,a5,a0
    80001b78:	0792                	slli	a5,a5,0x4
    80001b7a:	00012717          	auipc	a4,0x12
    80001b7e:	fb670713          	addi	a4,a4,-74 # 80013b30 <mlfq>
    80001b82:	97ba                	add	a5,a5,a4
    80001b84:	2117a223          	sw	a7,516(a5)
      // p->is_PQue = 0;
      break;
    }
  }

  p->is_PQue = 0;
    80001b88:	2005ac23          	sw	zero,536(a1)
}
    80001b8c:	6422                	ld	s0,8(sp)
    80001b8e:	0141                	addi	sp,sp,16
    80001b90:	8082                	ret

0000000080001b92 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001b92:	7139                	addi	sp,sp,-64
    80001b94:	fc06                	sd	ra,56(sp)
    80001b96:	f822                	sd	s0,48(sp)
    80001b98:	f426                	sd	s1,40(sp)
    80001b9a:	f04a                	sd	s2,32(sp)
    80001b9c:	ec4e                	sd	s3,24(sp)
    80001b9e:	e852                	sd	s4,16(sp)
    80001ba0:	e456                	sd	s5,8(sp)
    80001ba2:	e05a                	sd	s6,0(sp)
    80001ba4:	0080                	addi	s0,sp,64
    80001ba6:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001ba8:	00012497          	auipc	s1,0x12
    80001bac:	7c848493          	addi	s1,s1,1992 # 80014370 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001bb0:	8b26                	mv	s6,s1
    80001bb2:	ffc4a937          	lui	s2,0xffc4a
    80001bb6:	33f90913          	addi	s2,s2,831 # ffffffffffc4a33f <end+0xffffffff7fc221ef>
    80001bba:	093a                	slli	s2,s2,0xe
    80001bbc:	4a390913          	addi	s2,s2,1187
    80001bc0:	0932                	slli	s2,s2,0xc
    80001bc2:	3f190913          	addi	s2,s2,1009
    80001bc6:	0932                	slli	s2,s2,0xc
    80001bc8:	28d90913          	addi	s2,s2,653
    80001bcc:	040009b7          	lui	s3,0x4000
    80001bd0:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001bd2:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd4:	0001ba97          	auipc	s5,0x1b
    80001bd8:	19ca8a93          	addi	s5,s5,412 # 8001cd70 <tickslock>
    char *pa = kalloc();
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	f6c080e7          	jalr	-148(ra) # 80000b48 <kalloc>
    80001be4:	862a                	mv	a2,a0
    if (pa == 0)
    80001be6:	c121                	beqz	a0,80001c26 <proc_mapstacks+0x94>
    uint64 va = KSTACK((int)(p - proc));
    80001be8:	416485b3          	sub	a1,s1,s6
    80001bec:	858d                	srai	a1,a1,0x3
    80001bee:	032585b3          	mul	a1,a1,s2
    80001bf2:	2585                	addiw	a1,a1,1
    80001bf4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bf8:	4719                	li	a4,6
    80001bfa:	6685                	lui	a3,0x1
    80001bfc:	40b985b3          	sub	a1,s3,a1
    80001c00:	8552                	mv	a0,s4
    80001c02:	fffff097          	auipc	ra,0xfffff
    80001c06:	596080e7          	jalr	1430(ra) # 80001198 <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c0a:	22848493          	addi	s1,s1,552
    80001c0e:	fd5497e3          	bne	s1,s5,80001bdc <proc_mapstacks+0x4a>
  }
}
    80001c12:	70e2                	ld	ra,56(sp)
    80001c14:	7442                	ld	s0,48(sp)
    80001c16:	74a2                	ld	s1,40(sp)
    80001c18:	7902                	ld	s2,32(sp)
    80001c1a:	69e2                	ld	s3,24(sp)
    80001c1c:	6a42                	ld	s4,16(sp)
    80001c1e:	6aa2                	ld	s5,8(sp)
    80001c20:	6b02                	ld	s6,0(sp)
    80001c22:	6121                	addi	sp,sp,64
    80001c24:	8082                	ret
      panic("kalloc");
    80001c26:	00006517          	auipc	a0,0x6
    80001c2a:	5b250513          	addi	a0,a0,1458 # 800081d8 <etext+0x1d8>
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	932080e7          	jalr	-1742(ra) # 80000560 <panic>

0000000080001c36 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001c36:	7139                	addi	sp,sp,-64
    80001c38:	fc06                	sd	ra,56(sp)
    80001c3a:	f822                	sd	s0,48(sp)
    80001c3c:	f426                	sd	s1,40(sp)
    80001c3e:	f04a                	sd	s2,32(sp)
    80001c40:	ec4e                	sd	s3,24(sp)
    80001c42:	e852                	sd	s4,16(sp)
    80001c44:	e456                	sd	s5,8(sp)
    80001c46:	e05a                	sd	s6,0(sp)
    80001c48:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001c4a:	00006597          	auipc	a1,0x6
    80001c4e:	59658593          	addi	a1,a1,1430 # 800081e0 <etext+0x1e0>
    80001c52:	00012517          	auipc	a0,0x12
    80001c56:	aae50513          	addi	a0,a0,-1362 # 80013700 <pid_lock>
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	f4e080e7          	jalr	-178(ra) # 80000ba8 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c62:	00006597          	auipc	a1,0x6
    80001c66:	58658593          	addi	a1,a1,1414 # 800081e8 <etext+0x1e8>
    80001c6a:	00012517          	auipc	a0,0x12
    80001c6e:	aae50513          	addi	a0,a0,-1362 # 80013718 <wait_lock>
    80001c72:	fffff097          	auipc	ra,0xfffff
    80001c76:	f36080e7          	jalr	-202(ra) # 80000ba8 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c7a:	00012497          	auipc	s1,0x12
    80001c7e:	6f648493          	addi	s1,s1,1782 # 80014370 <proc>
  {
    initlock(&p->lock, "proc");
    80001c82:	00006b17          	auipc	s6,0x6
    80001c86:	576b0b13          	addi	s6,s6,1398 # 800081f8 <etext+0x1f8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001c8a:	8aa6                	mv	s5,s1
    80001c8c:	ffc4a937          	lui	s2,0xffc4a
    80001c90:	33f90913          	addi	s2,s2,831 # ffffffffffc4a33f <end+0xffffffff7fc221ef>
    80001c94:	093a                	slli	s2,s2,0xe
    80001c96:	4a390913          	addi	s2,s2,1187
    80001c9a:	0932                	slli	s2,s2,0xc
    80001c9c:	3f190913          	addi	s2,s2,1009
    80001ca0:	0932                	slli	s2,s2,0xc
    80001ca2:	28d90913          	addi	s2,s2,653
    80001ca6:	040009b7          	lui	s3,0x4000
    80001caa:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001cac:	09b2                	slli	s3,s3,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001cae:	0001ba17          	auipc	s4,0x1b
    80001cb2:	0c2a0a13          	addi	s4,s4,194 # 8001cd70 <tickslock>
    initlock(&p->lock, "proc");
    80001cb6:	85da                	mv	a1,s6
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	eee080e7          	jalr	-274(ra) # 80000ba8 <initlock>
    p->state = UNUSED;
    80001cc2:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001cc6:	415487b3          	sub	a5,s1,s5
    80001cca:	878d                	srai	a5,a5,0x3
    80001ccc:	032787b3          	mul	a5,a5,s2
    80001cd0:	2785                	addiw	a5,a5,1
    80001cd2:	00d7979b          	slliw	a5,a5,0xd
    80001cd6:	40f987b3          	sub	a5,s3,a5
    80001cda:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001cdc:	22848493          	addi	s1,s1,552
    80001ce0:	fd449be3          	bne	s1,s4,80001cb6 <procinit+0x80>
  }
  randstate = ticks;
    80001ce4:	00009797          	auipc	a5,0x9
    80001ce8:	7ac7e783          	lwu	a5,1964(a5) # 8000b490 <ticks>
    80001cec:	00009717          	auipc	a4,0x9
    80001cf0:	6ef73e23          	sd	a5,1788(a4) # 8000b3e8 <randstate>
}
    80001cf4:	70e2                	ld	ra,56(sp)
    80001cf6:	7442                	ld	s0,48(sp)
    80001cf8:	74a2                	ld	s1,40(sp)
    80001cfa:	7902                	ld	s2,32(sp)
    80001cfc:	69e2                	ld	s3,24(sp)
    80001cfe:	6a42                	ld	s4,16(sp)
    80001d00:	6aa2                	ld	s5,8(sp)
    80001d02:	6b02                	ld	s6,0(sp)
    80001d04:	6121                	addi	sp,sp,64
    80001d06:	8082                	ret

0000000080001d08 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001d08:	1141                	addi	sp,sp,-16
    80001d0a:	e422                	sd	s0,8(sp)
    80001d0c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d0e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001d10:	2501                	sext.w	a0,a0
    80001d12:	6422                	ld	s0,8(sp)
    80001d14:	0141                	addi	sp,sp,16
    80001d16:	8082                	ret

0000000080001d18 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001d18:	1141                	addi	sp,sp,-16
    80001d1a:	e422                	sd	s0,8(sp)
    80001d1c:	0800                	addi	s0,sp,16
    80001d1e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001d20:	2781                	sext.w	a5,a5
    80001d22:	079e                	slli	a5,a5,0x7
  return c;
}
    80001d24:	00012517          	auipc	a0,0x12
    80001d28:	a0c50513          	addi	a0,a0,-1524 # 80013730 <cpus>
    80001d2c:	953e                	add	a0,a0,a5
    80001d2e:	6422                	ld	s0,8(sp)
    80001d30:	0141                	addi	sp,sp,16
    80001d32:	8082                	ret

0000000080001d34 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001d34:	1101                	addi	sp,sp,-32
    80001d36:	ec06                	sd	ra,24(sp)
    80001d38:	e822                	sd	s0,16(sp)
    80001d3a:	e426                	sd	s1,8(sp)
    80001d3c:	1000                	addi	s0,sp,32
  push_off();
    80001d3e:	fffff097          	auipc	ra,0xfffff
    80001d42:	eae080e7          	jalr	-338(ra) # 80000bec <push_off>
    80001d46:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d48:	2781                	sext.w	a5,a5
    80001d4a:	079e                	slli	a5,a5,0x7
    80001d4c:	00012717          	auipc	a4,0x12
    80001d50:	9b470713          	addi	a4,a4,-1612 # 80013700 <pid_lock>
    80001d54:	97ba                	add	a5,a5,a4
    80001d56:	7b84                	ld	s1,48(a5)
  pop_off();
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	f34080e7          	jalr	-204(ra) # 80000c8c <pop_off>
  return p;
}
    80001d60:	8526                	mv	a0,s1
    80001d62:	60e2                	ld	ra,24(sp)
    80001d64:	6442                	ld	s0,16(sp)
    80001d66:	64a2                	ld	s1,8(sp)
    80001d68:	6105                	addi	sp,sp,32
    80001d6a:	8082                	ret

0000000080001d6c <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d6c:	1141                	addi	sp,sp,-16
    80001d6e:	e406                	sd	ra,8(sp)
    80001d70:	e022                	sd	s0,0(sp)
    80001d72:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	fc0080e7          	jalr	-64(ra) # 80001d34 <myproc>
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	f70080e7          	jalr	-144(ra) # 80000cec <release>

  if (first)
    80001d84:	00009797          	auipc	a5,0x9
    80001d88:	65c7a783          	lw	a5,1628(a5) # 8000b3e0 <first.1>
    80001d8c:	eb89                	bnez	a5,80001d9e <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d8e:	00001097          	auipc	ra,0x1
    80001d92:	ff2080e7          	jalr	-14(ra) # 80002d80 <usertrapret>
}
    80001d96:	60a2                	ld	ra,8(sp)
    80001d98:	6402                	ld	s0,0(sp)
    80001d9a:	0141                	addi	sp,sp,16
    80001d9c:	8082                	ret
    first = 0;
    80001d9e:	00009797          	auipc	a5,0x9
    80001da2:	6407a123          	sw	zero,1602(a5) # 8000b3e0 <first.1>
    fsinit(ROOTDEV);
    80001da6:	4505                	li	a0,1
    80001da8:	00002097          	auipc	ra,0x2
    80001dac:	0d0080e7          	jalr	208(ra) # 80003e78 <fsinit>
    80001db0:	bff9                	j	80001d8e <forkret+0x22>

0000000080001db2 <allocpid>:
{
    80001db2:	1101                	addi	sp,sp,-32
    80001db4:	ec06                	sd	ra,24(sp)
    80001db6:	e822                	sd	s0,16(sp)
    80001db8:	e426                	sd	s1,8(sp)
    80001dba:	e04a                	sd	s2,0(sp)
    80001dbc:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001dbe:	00012917          	auipc	s2,0x12
    80001dc2:	94290913          	addi	s2,s2,-1726 # 80013700 <pid_lock>
    80001dc6:	854a                	mv	a0,s2
    80001dc8:	fffff097          	auipc	ra,0xfffff
    80001dcc:	e70080e7          	jalr	-400(ra) # 80000c38 <acquire>
  pid = nextpid;
    80001dd0:	00009797          	auipc	a5,0x9
    80001dd4:	62078793          	addi	a5,a5,1568 # 8000b3f0 <nextpid>
    80001dd8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001dda:	0014871b          	addiw	a4,s1,1
    80001dde:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001de0:	854a                	mv	a0,s2
    80001de2:	fffff097          	auipc	ra,0xfffff
    80001de6:	f0a080e7          	jalr	-246(ra) # 80000cec <release>
}
    80001dea:	8526                	mv	a0,s1
    80001dec:	60e2                	ld	ra,24(sp)
    80001dee:	6442                	ld	s0,16(sp)
    80001df0:	64a2                	ld	s1,8(sp)
    80001df2:	6902                	ld	s2,0(sp)
    80001df4:	6105                	addi	sp,sp,32
    80001df6:	8082                	ret

0000000080001df8 <proc_pagetable>:
{
    80001df8:	1101                	addi	sp,sp,-32
    80001dfa:	ec06                	sd	ra,24(sp)
    80001dfc:	e822                	sd	s0,16(sp)
    80001dfe:	e426                	sd	s1,8(sp)
    80001e00:	e04a                	sd	s2,0(sp)
    80001e02:	1000                	addi	s0,sp,32
    80001e04:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	58c080e7          	jalr	1420(ra) # 80001392 <uvmcreate>
    80001e0e:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001e10:	c121                	beqz	a0,80001e50 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e12:	4729                	li	a4,10
    80001e14:	00005697          	auipc	a3,0x5
    80001e18:	1ec68693          	addi	a3,a3,492 # 80007000 <_trampoline>
    80001e1c:	6605                	lui	a2,0x1
    80001e1e:	040005b7          	lui	a1,0x4000
    80001e22:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e24:	05b2                	slli	a1,a1,0xc
    80001e26:	fffff097          	auipc	ra,0xfffff
    80001e2a:	2d2080e7          	jalr	722(ra) # 800010f8 <mappages>
    80001e2e:	02054863          	bltz	a0,80001e5e <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e32:	4719                	li	a4,6
    80001e34:	05893683          	ld	a3,88(s2)
    80001e38:	6605                	lui	a2,0x1
    80001e3a:	020005b7          	lui	a1,0x2000
    80001e3e:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e40:	05b6                	slli	a1,a1,0xd
    80001e42:	8526                	mv	a0,s1
    80001e44:	fffff097          	auipc	ra,0xfffff
    80001e48:	2b4080e7          	jalr	692(ra) # 800010f8 <mappages>
    80001e4c:	02054163          	bltz	a0,80001e6e <proc_pagetable+0x76>
}
    80001e50:	8526                	mv	a0,s1
    80001e52:	60e2                	ld	ra,24(sp)
    80001e54:	6442                	ld	s0,16(sp)
    80001e56:	64a2                	ld	s1,8(sp)
    80001e58:	6902                	ld	s2,0(sp)
    80001e5a:	6105                	addi	sp,sp,32
    80001e5c:	8082                	ret
    uvmfree(pagetable, 0);
    80001e5e:	4581                	li	a1,0
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	742080e7          	jalr	1858(ra) # 800015a4 <uvmfree>
    return 0;
    80001e6a:	4481                	li	s1,0
    80001e6c:	b7d5                	j	80001e50 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e6e:	4681                	li	a3,0
    80001e70:	4605                	li	a2,1
    80001e72:	040005b7          	lui	a1,0x4000
    80001e76:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e78:	05b2                	slli	a1,a1,0xc
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	442080e7          	jalr	1090(ra) # 800012be <uvmunmap>
    uvmfree(pagetable, 0);
    80001e84:	4581                	li	a1,0
    80001e86:	8526                	mv	a0,s1
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	71c080e7          	jalr	1820(ra) # 800015a4 <uvmfree>
    return 0;
    80001e90:	4481                	li	s1,0
    80001e92:	bf7d                	j	80001e50 <proc_pagetable+0x58>

0000000080001e94 <proc_freepagetable>:
{
    80001e94:	1101                	addi	sp,sp,-32
    80001e96:	ec06                	sd	ra,24(sp)
    80001e98:	e822                	sd	s0,16(sp)
    80001e9a:	e426                	sd	s1,8(sp)
    80001e9c:	e04a                	sd	s2,0(sp)
    80001e9e:	1000                	addi	s0,sp,32
    80001ea0:	84aa                	mv	s1,a0
    80001ea2:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ea4:	4681                	li	a3,0
    80001ea6:	4605                	li	a2,1
    80001ea8:	040005b7          	lui	a1,0x4000
    80001eac:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001eae:	05b2                	slli	a1,a1,0xc
    80001eb0:	fffff097          	auipc	ra,0xfffff
    80001eb4:	40e080e7          	jalr	1038(ra) # 800012be <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001eb8:	4681                	li	a3,0
    80001eba:	4605                	li	a2,1
    80001ebc:	020005b7          	lui	a1,0x2000
    80001ec0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ec2:	05b6                	slli	a1,a1,0xd
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	3f8080e7          	jalr	1016(ra) # 800012be <uvmunmap>
  uvmfree(pagetable, sz);
    80001ece:	85ca                	mv	a1,s2
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	6d2080e7          	jalr	1746(ra) # 800015a4 <uvmfree>
}
    80001eda:	60e2                	ld	ra,24(sp)
    80001edc:	6442                	ld	s0,16(sp)
    80001ede:	64a2                	ld	s1,8(sp)
    80001ee0:	6902                	ld	s2,0(sp)
    80001ee2:	6105                	addi	sp,sp,32
    80001ee4:	8082                	ret

0000000080001ee6 <freeproc>:
{
    80001ee6:	1101                	addi	sp,sp,-32
    80001ee8:	ec06                	sd	ra,24(sp)
    80001eea:	e822                	sd	s0,16(sp)
    80001eec:	e426                	sd	s1,8(sp)
    80001eee:	1000                	addi	s0,sp,32
    80001ef0:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001ef2:	6d28                	ld	a0,88(a0)
    80001ef4:	c509                	beqz	a0,80001efe <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001ef6:	fffff097          	auipc	ra,0xfffff
    80001efa:	b54080e7          	jalr	-1196(ra) # 80000a4a <kfree>
  p->trapframe = 0;
    80001efe:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001f02:	68a8                	ld	a0,80(s1)
    80001f04:	c511                	beqz	a0,80001f10 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f06:	64ac                	ld	a1,72(s1)
    80001f08:	00000097          	auipc	ra,0x0
    80001f0c:	f8c080e7          	jalr	-116(ra) # 80001e94 <proc_freepagetable>
  p->pagetable = 0;
    80001f10:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001f14:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001f18:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001f1c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001f20:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001f24:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001f28:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001f2c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001f30:	0004ac23          	sw	zero,24(s1)
  p->is_PQue = 0;
    80001f34:	2004ac23          	sw	zero,536(s1)
}
    80001f38:	60e2                	ld	ra,24(sp)
    80001f3a:	6442                	ld	s0,16(sp)
    80001f3c:	64a2                	ld	s1,8(sp)
    80001f3e:	6105                	addi	sp,sp,32
    80001f40:	8082                	ret

0000000080001f42 <allocproc>:
{
    80001f42:	1101                	addi	sp,sp,-32
    80001f44:	ec06                	sd	ra,24(sp)
    80001f46:	e822                	sd	s0,16(sp)
    80001f48:	e426                	sd	s1,8(sp)
    80001f4a:	e04a                	sd	s2,0(sp)
    80001f4c:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001f4e:	00012497          	auipc	s1,0x12
    80001f52:	42248493          	addi	s1,s1,1058 # 80014370 <proc>
    80001f56:	0001b917          	auipc	s2,0x1b
    80001f5a:	e1a90913          	addi	s2,s2,-486 # 8001cd70 <tickslock>
    acquire(&p->lock);
    80001f5e:	8526                	mv	a0,s1
    80001f60:	fffff097          	auipc	ra,0xfffff
    80001f64:	cd8080e7          	jalr	-808(ra) # 80000c38 <acquire>
    if (p->state == UNUSED)
    80001f68:	4c9c                	lw	a5,24(s1)
    80001f6a:	cf81                	beqz	a5,80001f82 <allocproc+0x40>
      release(&p->lock);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	d7e080e7          	jalr	-642(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001f76:	22848493          	addi	s1,s1,552
    80001f7a:	ff2492e3          	bne	s1,s2,80001f5e <allocproc+0x1c>
  return 0;
    80001f7e:	4481                	li	s1,0
    80001f80:	a89d                	j	80001ff6 <allocproc+0xb4>
  p->pid = allocpid();
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	e30080e7          	jalr	-464(ra) # 80001db2 <allocpid>
    80001f8a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001f8c:	4785                	li	a5,1
    80001f8e:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	bb8080e7          	jalr	-1096(ra) # 80000b48 <kalloc>
    80001f98:	892a                	mv	s2,a0
    80001f9a:	eca8                	sd	a0,88(s1)
    80001f9c:	c525                	beqz	a0,80002004 <allocproc+0xc2>
  p->pagetable = proc_pagetable(p);
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	e58080e7          	jalr	-424(ra) # 80001df8 <proc_pagetable>
    80001fa8:	892a                	mv	s2,a0
    80001faa:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001fac:	c925                	beqz	a0,8000201c <allocproc+0xda>
  memset(&p->context, 0, sizeof(p->context));
    80001fae:	07000613          	li	a2,112
    80001fb2:	4581                	li	a1,0
    80001fb4:	06048513          	addi	a0,s1,96
    80001fb8:	fffff097          	auipc	ra,0xfffff
    80001fbc:	d7c080e7          	jalr	-644(ra) # 80000d34 <memset>
  p->context.ra = (uint64)forkret;
    80001fc0:	00000797          	auipc	a5,0x0
    80001fc4:	dac78793          	addi	a5,a5,-596 # 80001d6c <forkret>
    80001fc8:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001fca:	60bc                	ld	a5,64(s1)
    80001fcc:	6705                	lui	a4,0x1
    80001fce:	97ba                	add	a5,a5,a4
    80001fd0:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001fd2:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001fd6:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001fda:	00009797          	auipc	a5,0x9
    80001fde:	4b67a783          	lw	a5,1206(a5) # 8000b490 <ticks>
    80001fe2:	16f4a623          	sw	a5,364(s1)
  p->CQue_no = 0;
    80001fe6:	2004aa23          	sw	zero,532(s1)
  p->is_PQue = 0;
    80001fea:	2004ac23          	sw	zero,536(s1)
  p->WaitTime = 0;
    80001fee:	2004ae23          	sw	zero,540(s1)
  p->RunTime = 0;
    80001ff2:	2204a023          	sw	zero,544(s1)
}
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	60e2                	ld	ra,24(sp)
    80001ffa:	6442                	ld	s0,16(sp)
    80001ffc:	64a2                	ld	s1,8(sp)
    80001ffe:	6902                	ld	s2,0(sp)
    80002000:	6105                	addi	sp,sp,32
    80002002:	8082                	ret
    freeproc(p);
    80002004:	8526                	mv	a0,s1
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	ee0080e7          	jalr	-288(ra) # 80001ee6 <freeproc>
    release(&p->lock);
    8000200e:	8526                	mv	a0,s1
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	cdc080e7          	jalr	-804(ra) # 80000cec <release>
    return 0;
    80002018:	84ca                	mv	s1,s2
    8000201a:	bff1                	j	80001ff6 <allocproc+0xb4>
    freeproc(p);
    8000201c:	8526                	mv	a0,s1
    8000201e:	00000097          	auipc	ra,0x0
    80002022:	ec8080e7          	jalr	-312(ra) # 80001ee6 <freeproc>
    release(&p->lock);
    80002026:	8526                	mv	a0,s1
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	cc4080e7          	jalr	-828(ra) # 80000cec <release>
    return 0;
    80002030:	84ca                	mv	s1,s2
    80002032:	b7d1                	j	80001ff6 <allocproc+0xb4>

0000000080002034 <userinit>:
{
    80002034:	1101                	addi	sp,sp,-32
    80002036:	ec06                	sd	ra,24(sp)
    80002038:	e822                	sd	s0,16(sp)
    8000203a:	e426                	sd	s1,8(sp)
    8000203c:	1000                	addi	s0,sp,32
  p = allocproc();
    8000203e:	00000097          	auipc	ra,0x0
    80002042:	f04080e7          	jalr	-252(ra) # 80001f42 <allocproc>
    80002046:	84aa                	mv	s1,a0
  initproc = p;
    80002048:	00009797          	auipc	a5,0x9
    8000204c:	44a7b023          	sd	a0,1088(a5) # 8000b488 <initproc>
  initialize();
    80002050:	00000097          	auipc	ra,0x0
    80002054:	8a4080e7          	jalr	-1884(ra) # 800018f4 <initialize>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80002058:	03400613          	li	a2,52
    8000205c:	00009597          	auipc	a1,0x9
    80002060:	3a458593          	addi	a1,a1,932 # 8000b400 <initcode>
    80002064:	68a8                	ld	a0,80(s1)
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	35a080e7          	jalr	858(ra) # 800013c0 <uvmfirst>
  p->sz = PGSIZE;
    8000206e:	6785                	lui	a5,0x1
    80002070:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80002072:	6cb8                	ld	a4,88(s1)
    80002074:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80002078:	6cb8                	ld	a4,88(s1)
    8000207a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    8000207c:	4641                	li	a2,16
    8000207e:	00006597          	auipc	a1,0x6
    80002082:	18258593          	addi	a1,a1,386 # 80008200 <etext+0x200>
    80002086:	15848513          	addi	a0,s1,344
    8000208a:	fffff097          	auipc	ra,0xfffff
    8000208e:	dec080e7          	jalr	-532(ra) # 80000e76 <safestrcpy>
  p->cwd = namei("/");
    80002092:	00006517          	auipc	a0,0x6
    80002096:	17e50513          	addi	a0,a0,382 # 80008210 <etext+0x210>
    8000209a:	00003097          	auipc	ra,0x3
    8000209e:	830080e7          	jalr	-2000(ra) # 800048ca <namei>
    800020a2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    800020a6:	478d                	li	a5,3
    800020a8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800020aa:	8526                	mv	a0,s1
    800020ac:	fffff097          	auipc	ra,0xfffff
    800020b0:	c40080e7          	jalr	-960(ra) # 80000cec <release>
}
    800020b4:	60e2                	ld	ra,24(sp)
    800020b6:	6442                	ld	s0,16(sp)
    800020b8:	64a2                	ld	s1,8(sp)
    800020ba:	6105                	addi	sp,sp,32
    800020bc:	8082                	ret

00000000800020be <growproc>:
{
    800020be:	1101                	addi	sp,sp,-32
    800020c0:	ec06                	sd	ra,24(sp)
    800020c2:	e822                	sd	s0,16(sp)
    800020c4:	e426                	sd	s1,8(sp)
    800020c6:	e04a                	sd	s2,0(sp)
    800020c8:	1000                	addi	s0,sp,32
    800020ca:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	c68080e7          	jalr	-920(ra) # 80001d34 <myproc>
    800020d4:	84aa                	mv	s1,a0
  sz = p->sz;
    800020d6:	652c                	ld	a1,72(a0)
  if (n > 0)
    800020d8:	01204c63          	bgtz	s2,800020f0 <growproc+0x32>
  else if (n < 0)
    800020dc:	02094663          	bltz	s2,80002108 <growproc+0x4a>
  p->sz = sz;
    800020e0:	e4ac                	sd	a1,72(s1)
  return 0;
    800020e2:	4501                	li	a0,0
}
    800020e4:	60e2                	ld	ra,24(sp)
    800020e6:	6442                	ld	s0,16(sp)
    800020e8:	64a2                	ld	s1,8(sp)
    800020ea:	6902                	ld	s2,0(sp)
    800020ec:	6105                	addi	sp,sp,32
    800020ee:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    800020f0:	4691                	li	a3,4
    800020f2:	00b90633          	add	a2,s2,a1
    800020f6:	6928                	ld	a0,80(a0)
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	382080e7          	jalr	898(ra) # 8000147a <uvmalloc>
    80002100:	85aa                	mv	a1,a0
    80002102:	fd79                	bnez	a0,800020e0 <growproc+0x22>
      return -1;
    80002104:	557d                	li	a0,-1
    80002106:	bff9                	j	800020e4 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002108:	00b90633          	add	a2,s2,a1
    8000210c:	6928                	ld	a0,80(a0)
    8000210e:	fffff097          	auipc	ra,0xfffff
    80002112:	324080e7          	jalr	804(ra) # 80001432 <uvmdealloc>
    80002116:	85aa                	mv	a1,a0
    80002118:	b7e1                	j	800020e0 <growproc+0x22>

000000008000211a <fork>:
{
    8000211a:	7139                	addi	sp,sp,-64
    8000211c:	fc06                	sd	ra,56(sp)
    8000211e:	f822                	sd	s0,48(sp)
    80002120:	f04a                	sd	s2,32(sp)
    80002122:	e456                	sd	s5,8(sp)
    80002124:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80002126:	00000097          	auipc	ra,0x0
    8000212a:	c0e080e7          	jalr	-1010(ra) # 80001d34 <myproc>
    8000212e:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80002130:	00000097          	auipc	ra,0x0
    80002134:	e12080e7          	jalr	-494(ra) # 80001f42 <allocproc>
    80002138:	12050463          	beqz	a0,80002260 <fork+0x146>
    8000213c:	ec4e                	sd	s3,24(sp)
    8000213e:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002140:	048ab603          	ld	a2,72(s5)
    80002144:	692c                	ld	a1,80(a0)
    80002146:	050ab503          	ld	a0,80(s5)
    8000214a:	fffff097          	auipc	ra,0xfffff
    8000214e:	494080e7          	jalr	1172(ra) # 800015de <uvmcopy>
    80002152:	04054e63          	bltz	a0,800021ae <fork+0x94>
    80002156:	f426                	sd	s1,40(sp)
    80002158:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    8000215a:	048ab783          	ld	a5,72(s5)
    8000215e:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002162:	058ab683          	ld	a3,88(s5)
    80002166:	87b6                	mv	a5,a3
    80002168:	0589b703          	ld	a4,88(s3)
    8000216c:	12068693          	addi	a3,a3,288
    80002170:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002174:	6788                	ld	a0,8(a5)
    80002176:	6b8c                	ld	a1,16(a5)
    80002178:	6f90                	ld	a2,24(a5)
    8000217a:	01073023          	sd	a6,0(a4)
    8000217e:	e708                	sd	a0,8(a4)
    80002180:	eb0c                	sd	a1,16(a4)
    80002182:	ef10                	sd	a2,24(a4)
    80002184:	02078793          	addi	a5,a5,32
    80002188:	02070713          	addi	a4,a4,32
    8000218c:	fed792e3          	bne	a5,a3,80002170 <fork+0x56>
  np->trapframe->a0 = 0;
    80002190:	0589b783          	ld	a5,88(s3)
    80002194:	0607b823          	sd	zero,112(a5)
  np->tickets = p->tickets;
    80002198:	20caa783          	lw	a5,524(s5)
    8000219c:	20f9a623          	sw	a5,524(s3)
  for (i = 0; i < NOFILE; i++)
    800021a0:	0d0a8493          	addi	s1,s5,208
    800021a4:	0d098913          	addi	s2,s3,208
    800021a8:	150a8a13          	addi	s4,s5,336
    800021ac:	a015                	j	800021d0 <fork+0xb6>
    freeproc(np);
    800021ae:	854e                	mv	a0,s3
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	d36080e7          	jalr	-714(ra) # 80001ee6 <freeproc>
    release(&np->lock);
    800021b8:	854e                	mv	a0,s3
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	b32080e7          	jalr	-1230(ra) # 80000cec <release>
    return -1;
    800021c2:	597d                	li	s2,-1
    800021c4:	69e2                	ld	s3,24(sp)
    800021c6:	a071                	j	80002252 <fork+0x138>
  for (i = 0; i < NOFILE; i++)
    800021c8:	04a1                	addi	s1,s1,8
    800021ca:	0921                	addi	s2,s2,8
    800021cc:	01448b63          	beq	s1,s4,800021e2 <fork+0xc8>
    if (p->ofile[i])
    800021d0:	6088                	ld	a0,0(s1)
    800021d2:	d97d                	beqz	a0,800021c8 <fork+0xae>
      np->ofile[i] = filedup(p->ofile[i]);
    800021d4:	00003097          	auipc	ra,0x3
    800021d8:	d6e080e7          	jalr	-658(ra) # 80004f42 <filedup>
    800021dc:	00a93023          	sd	a0,0(s2)
    800021e0:	b7e5                	j	800021c8 <fork+0xae>
  np->cwd = idup(p->cwd);
    800021e2:	150ab503          	ld	a0,336(s5)
    800021e6:	00002097          	auipc	ra,0x2
    800021ea:	ed8080e7          	jalr	-296(ra) # 800040be <idup>
    800021ee:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021f2:	4641                	li	a2,16
    800021f4:	158a8593          	addi	a1,s5,344
    800021f8:	15898513          	addi	a0,s3,344
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	c7a080e7          	jalr	-902(ra) # 80000e76 <safestrcpy>
  pid = np->pid;
    80002204:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002208:	854e                	mv	a0,s3
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	ae2080e7          	jalr	-1310(ra) # 80000cec <release>
  acquire(&wait_lock);
    80002212:	00011497          	auipc	s1,0x11
    80002216:	50648493          	addi	s1,s1,1286 # 80013718 <wait_lock>
    8000221a:	8526                	mv	a0,s1
    8000221c:	fffff097          	auipc	ra,0xfffff
    80002220:	a1c080e7          	jalr	-1508(ra) # 80000c38 <acquire>
  np->parent = p;
    80002224:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80002228:	8526                	mv	a0,s1
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	ac2080e7          	jalr	-1342(ra) # 80000cec <release>
  acquire(&np->lock);
    80002232:	854e                	mv	a0,s3
    80002234:	fffff097          	auipc	ra,0xfffff
    80002238:	a04080e7          	jalr	-1532(ra) # 80000c38 <acquire>
  np->state = RUNNABLE;
    8000223c:	478d                	li	a5,3
    8000223e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002242:	854e                	mv	a0,s3
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	aa8080e7          	jalr	-1368(ra) # 80000cec <release>
  return pid;
    8000224c:	74a2                	ld	s1,40(sp)
    8000224e:	69e2                	ld	s3,24(sp)
    80002250:	6a42                	ld	s4,16(sp)
}
    80002252:	854a                	mv	a0,s2
    80002254:	70e2                	ld	ra,56(sp)
    80002256:	7442                	ld	s0,48(sp)
    80002258:	7902                	ld	s2,32(sp)
    8000225a:	6aa2                	ld	s5,8(sp)
    8000225c:	6121                	addi	sp,sp,64
    8000225e:	8082                	ret
    return -1;
    80002260:	597d                	li	s2,-1
    80002262:	bfc5                	j	80002252 <fork+0x138>

0000000080002264 <scheduler>:
{
    80002264:	715d                	addi	sp,sp,-80
    80002266:	e486                	sd	ra,72(sp)
    80002268:	e0a2                	sd	s0,64(sp)
    8000226a:	fc26                	sd	s1,56(sp)
    8000226c:	f84a                	sd	s2,48(sp)
    8000226e:	f44e                	sd	s3,40(sp)
    80002270:	f052                	sd	s4,32(sp)
    80002272:	ec56                	sd	s5,24(sp)
    80002274:	e85a                	sd	s6,16(sp)
    80002276:	e45e                	sd	s7,8(sp)
    80002278:	e062                	sd	s8,0(sp)
    8000227a:	0880                	addi	s0,sp,80
    8000227c:	8792                	mv	a5,tp
  int id = r_tp();
    8000227e:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002280:	00779b13          	slli	s6,a5,0x7
    80002284:	00011717          	auipc	a4,0x11
    80002288:	47c70713          	addi	a4,a4,1148 # 80013700 <pid_lock>
    8000228c:	975a                	add	a4,a4,s6
    8000228e:	02073823          	sd	zero,48(a4)
              swtch(&c->context, &work_proc->context);
    80002292:	00011717          	auipc	a4,0x11
    80002296:	4a670713          	addi	a4,a4,1190 # 80013738 <cpus+0x8>
    8000229a:	9b3a                	add	s6,s6,a4
      if(p->state == RUNNABLE && p->is_PQue == 0){
    8000229c:	490d                	li	s2,3
      if((p->state == UNUSED || p->state == ZOMBIE ) && p->is_PQue == 1){
    8000229e:	4a15                	li	s4,5
    for(p = proc;p < &proc[NPROC] ;p++){
    800022a0:	0001b997          	auipc	s3,0x1b
    800022a4:	ad098993          	addi	s3,s3,-1328 # 8001cd70 <tickslock>
              c->proc = work_proc;
    800022a8:	079e                	slli	a5,a5,0x7
    800022aa:	00011a97          	auipc	s5,0x11
    800022ae:	456a8a93          	addi	s5,s5,1110 # 80013700 <pid_lock>
    800022b2:	9abe                	add	s5,s5,a5
    800022b4:	a2a5                	j	8000241c <scheduler+0x1b8>
        release(&p->lock);
    800022b6:	8526                	mv	a0,s1
    800022b8:	fffff097          	auipc	ra,0xfffff
    800022bc:	a34080e7          	jalr	-1484(ra) # 80000cec <release>
        continue;
    800022c0:	a099                	j	80002306 <scheduler+0xa2>
      if(p->state == RUNNABLE && p->is_PQue == 0){
    800022c2:	2184a783          	lw	a5,536(s1)
    800022c6:	eb9d                	bnez	a5,800022fc <scheduler+0x98>
        enque_mlfq(p,p->CQue_no);
    800022c8:	2144a583          	lw	a1,532(s1)
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	684080e7          	jalr	1668(ra) # 80001952 <enque_mlfq>
        p->is_PQue = 1;
    800022d6:	2174ac23          	sw	s7,536(s1)
      if((p->state == UNUSED || p->state == ZOMBIE ) && p->is_PQue == 1){
    800022da:	4c9c                	lw	a5,24(s1)
    800022dc:	14079c63          	bnez	a5,80002434 <scheduler+0x1d0>
        remProcess(p->CQue_no,p);
    800022e0:	85a6                	mv	a1,s1
    800022e2:	2144a503          	lw	a0,532(s1)
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	7e8080e7          	jalr	2024(ra) # 80001ace <remProcess>
        p->is_PQue = 0;
    800022ee:	2004ac23          	sw	zero,536(s1)
    800022f2:	a029                	j	800022fc <scheduler+0x98>
      if((p->state == UNUSED || p->state == ZOMBIE ) && p->is_PQue == 1){
    800022f4:	2184a783          	lw	a5,536(s1)
    800022f8:	ff7784e3          	beq	a5,s7,800022e0 <scheduler+0x7c>
      release(&p->lock);
    800022fc:	8526                	mv	a0,s1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	9ee080e7          	jalr	-1554(ra) # 80000cec <release>
    for(p = proc;p < &proc[NPROC] ;p++){
    80002306:	22848493          	addi	s1,s1,552
    8000230a:	03348063          	beq	s1,s3,8000232a <scheduler+0xc6>
      acquire(&p->lock);
    8000230e:	8526                	mv	a0,s1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	928080e7          	jalr	-1752(ra) # 80000c38 <acquire>
      if (p->state == SLEEPING || p->state == UNUSED)
    80002318:	4c9c                	lw	a5,24(s1)
    8000231a:	ffd7f713          	andi	a4,a5,-3
    8000231e:	df41                	beqz	a4,800022b6 <scheduler+0x52>
      if(p->state == RUNNABLE && p->is_PQue == 0){
    80002320:	fb2781e3          	beq	a5,s2,800022c2 <scheduler+0x5e>
      if((p->state == UNUSED || p->state == ZOMBIE ) && p->is_PQue == 1){
    80002324:	fd479ce3          	bne	a5,s4,800022fc <scheduler+0x98>
    80002328:	b7f1                	j	800022f4 <scheduler+0x90>
    8000232a:	00012c17          	auipc	s8,0x12
    8000232e:	806c0c13          	addi	s8,s8,-2042 # 80013b30 <mlfq>
      for (int i = 0; i < totalQs; i++) {
    80002332:	4b81                	li	s7,0
    for(p = proc;p < &proc[NPROC] ;p++){
    80002334:	4481                	li	s1,0
    80002336:	a079                	j	800023c4 <scheduler+0x160>
          while (mlfq[i].tail_ptr > 0) {
    80002338:	00012b97          	auipc	s7,0x12
    8000233c:	7f8b8b93          	addi	s7,s7,2040 # 80014b30 <proc+0x7c0>
    80002340:	834ba783          	lw	a5,-1996(s7)
    80002344:	0cf05c63          	blez	a5,8000241c <scheduler+0x1b8>
            work_proc = deque_mlfq(i);
    80002348:	854a                	mv	a0,s2
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	6e6080e7          	jalr	1766(ra) # 80001a30 <deque_mlfq>
    80002352:	84aa                	mv	s1,a0
            work_proc->is_PQue = 0;
    80002354:	20052c23          	sw	zero,536(a0)
            if (work_proc->state == RUNNABLE) {
    80002358:	4d1c                	lw	a5,24(a0)
    8000235a:	ff2793e3          	bne	a5,s2,80002340 <scheduler+0xdc>
              acquire(&work_proc->lock);
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	8da080e7          	jalr	-1830(ra) # 80000c38 <acquire>
              work_proc->state = RUNNING;
    80002366:	4791                	li	a5,4
    80002368:	cc9c                	sw	a5,24(s1)
              c->proc = work_proc;
    8000236a:	029ab823          	sd	s1,48(s5)
              swtch(&c->context, &work_proc->context);
    8000236e:	06048593          	addi	a1,s1,96
    80002372:	855a                	mv	a0,s6
    80002374:	00001097          	auipc	ra,0x1
    80002378:	962080e7          	jalr	-1694(ra) # 80002cd6 <swtch>
              c->proc = 0;
    8000237c:	020ab823          	sd	zero,48(s5)
              release(&work_proc->lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	96a080e7          	jalr	-1686(ra) # 80000cec <release>
              acquire(&work_proc->lock);
    8000238a:	8526                	mv	a0,s1
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	8ac080e7          	jalr	-1876(ra) # 80000c38 <acquire>
              if (work_proc->state == RUNNABLE || work_proc->state == RUNNING) {
    80002394:	4c9c                	lw	a5,24(s1)
    80002396:	37f5                	addiw	a5,a5,-3
    80002398:	4705                	li	a4,1
    8000239a:	00f77863          	bgeu	a4,a5,800023aa <scheduler+0x146>
              release(&work_proc->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	94c080e7          	jalr	-1716(ra) # 80000cec <release>
              break;
    800023a8:	a895                	j	8000241c <scheduler+0x1b8>
                enque_mlfq(work_proc, totalQs - 1);  // Re-enqueue in the lowest queue
    800023aa:	85ca                	mv	a1,s2
    800023ac:	8526                	mv	a0,s1
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	5a4080e7          	jalr	1444(ra) # 80001952 <enque_mlfq>
    800023b6:	b7e5                	j	8000239e <scheduler+0x13a>
      for (int i = 0; i < totalQs; i++) {
    800023b8:	2b85                	addiw	s7,s7,1
        if (work_proc != 0) {
    800023ba:	e0ad                	bnez	s1,8000241c <scheduler+0x1b8>
        if (i == totalQs - 1) {
    800023bc:	f72b8ee3          	beq	s7,s2,80002338 <scheduler+0xd4>
        if (work_proc != 0) {
    800023c0:	210c0c13          	addi	s8,s8,528
          while (mlfq[i].tail_ptr > 0) {
    800023c4:	204c2783          	lw	a5,516(s8)
    800023c8:	fef058e3          	blez	a5,800023b8 <scheduler+0x154>
            work_proc = deque_mlfq(i);
    800023cc:	855e                	mv	a0,s7
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	662080e7          	jalr	1634(ra) # 80001a30 <deque_mlfq>
    800023d6:	84aa                	mv	s1,a0
            work_proc->is_PQue = 0;
    800023d8:	20052c23          	sw	zero,536(a0)
            if (work_proc->state == RUNNABLE) {
    800023dc:	4d1c                	lw	a5,24(a0)
    800023de:	ff2793e3          	bne	a5,s2,800023c4 <scheduler+0x160>
              add_front_mlfq(work_proc,work_proc->CQue_no);
    800023e2:	21452583          	lw	a1,532(a0)
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	5c6080e7          	jalr	1478(ra) # 800019ac <add_front_mlfq>
              acquire(&work_proc->lock);
    800023ee:	8526                	mv	a0,s1
    800023f0:	fffff097          	auipc	ra,0xfffff
    800023f4:	848080e7          	jalr	-1976(ra) # 80000c38 <acquire>
              work_proc->state = RUNNING;
    800023f8:	4791                	li	a5,4
    800023fa:	cc9c                	sw	a5,24(s1)
              c->proc = work_proc;
    800023fc:	029ab823          	sd	s1,48(s5)
              swtch(&c->context, &work_proc->context);
    80002400:	06048593          	addi	a1,s1,96
    80002404:	855a                	mv	a0,s6
    80002406:	00001097          	auipc	ra,0x1
    8000240a:	8d0080e7          	jalr	-1840(ra) # 80002cd6 <swtch>
              c->proc = 0;
    8000240e:	020ab823          	sd	zero,48(s5)
              release(&work_proc->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	8d8080e7          	jalr	-1832(ra) # 80000cec <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000241c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002420:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002424:	10079073          	csrw	sstatus,a5
    for(p = proc;p < &proc[NPROC] ;p++){
    80002428:	00012497          	auipc	s1,0x12
    8000242c:	f4848493          	addi	s1,s1,-184 # 80014370 <proc>
      if((p->state == UNUSED || p->state == ZOMBIE ) && p->is_PQue == 1){
    80002430:	4b85                	li	s7,1
    80002432:	bdf1                	j	8000230e <scheduler+0xaa>
    80002434:	4715                	li	a4,5
    80002436:	ece793e3          	bne	a5,a4,800022fc <scheduler+0x98>
    8000243a:	b55d                	j	800022e0 <scheduler+0x7c>

000000008000243c <sched>:
{
    8000243c:	7179                	addi	sp,sp,-48
    8000243e:	f406                	sd	ra,40(sp)
    80002440:	f022                	sd	s0,32(sp)
    80002442:	ec26                	sd	s1,24(sp)
    80002444:	e84a                	sd	s2,16(sp)
    80002446:	e44e                	sd	s3,8(sp)
    80002448:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	8ea080e7          	jalr	-1814(ra) # 80001d34 <myproc>
    80002452:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002454:	ffffe097          	auipc	ra,0xffffe
    80002458:	76a080e7          	jalr	1898(ra) # 80000bbe <holding>
    8000245c:	c93d                	beqz	a0,800024d2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000245e:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002460:	2781                	sext.w	a5,a5
    80002462:	079e                	slli	a5,a5,0x7
    80002464:	00011717          	auipc	a4,0x11
    80002468:	29c70713          	addi	a4,a4,668 # 80013700 <pid_lock>
    8000246c:	97ba                	add	a5,a5,a4
    8000246e:	0a87a703          	lw	a4,168(a5)
    80002472:	4785                	li	a5,1
    80002474:	06f71763          	bne	a4,a5,800024e2 <sched+0xa6>
  if (p->state == RUNNING)
    80002478:	4c98                	lw	a4,24(s1)
    8000247a:	4791                	li	a5,4
    8000247c:	06f70b63          	beq	a4,a5,800024f2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002480:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002484:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002486:	efb5                	bnez	a5,80002502 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002488:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000248a:	00011917          	auipc	s2,0x11
    8000248e:	27690913          	addi	s2,s2,630 # 80013700 <pid_lock>
    80002492:	2781                	sext.w	a5,a5
    80002494:	079e                	slli	a5,a5,0x7
    80002496:	97ca                	add	a5,a5,s2
    80002498:	0ac7a983          	lw	s3,172(a5)
    8000249c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000249e:	2781                	sext.w	a5,a5
    800024a0:	079e                	slli	a5,a5,0x7
    800024a2:	00011597          	auipc	a1,0x11
    800024a6:	29658593          	addi	a1,a1,662 # 80013738 <cpus+0x8>
    800024aa:	95be                	add	a1,a1,a5
    800024ac:	06048513          	addi	a0,s1,96
    800024b0:	00001097          	auipc	ra,0x1
    800024b4:	826080e7          	jalr	-2010(ra) # 80002cd6 <swtch>
    800024b8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800024ba:	2781                	sext.w	a5,a5
    800024bc:	079e                	slli	a5,a5,0x7
    800024be:	993e                	add	s2,s2,a5
    800024c0:	0b392623          	sw	s3,172(s2)
}
    800024c4:	70a2                	ld	ra,40(sp)
    800024c6:	7402                	ld	s0,32(sp)
    800024c8:	64e2                	ld	s1,24(sp)
    800024ca:	6942                	ld	s2,16(sp)
    800024cc:	69a2                	ld	s3,8(sp)
    800024ce:	6145                	addi	sp,sp,48
    800024d0:	8082                	ret
    panic("sched p->lock");
    800024d2:	00006517          	auipc	a0,0x6
    800024d6:	d4650513          	addi	a0,a0,-698 # 80008218 <etext+0x218>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	086080e7          	jalr	134(ra) # 80000560 <panic>
    panic("sched locks");
    800024e2:	00006517          	auipc	a0,0x6
    800024e6:	d4650513          	addi	a0,a0,-698 # 80008228 <etext+0x228>
    800024ea:	ffffe097          	auipc	ra,0xffffe
    800024ee:	076080e7          	jalr	118(ra) # 80000560 <panic>
    panic("sched running");
    800024f2:	00006517          	auipc	a0,0x6
    800024f6:	d4650513          	addi	a0,a0,-698 # 80008238 <etext+0x238>
    800024fa:	ffffe097          	auipc	ra,0xffffe
    800024fe:	066080e7          	jalr	102(ra) # 80000560 <panic>
    panic("sched interruptible");
    80002502:	00006517          	auipc	a0,0x6
    80002506:	d4650513          	addi	a0,a0,-698 # 80008248 <etext+0x248>
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	056080e7          	jalr	86(ra) # 80000560 <panic>

0000000080002512 <yield>:
{
    80002512:	1101                	addi	sp,sp,-32
    80002514:	ec06                	sd	ra,24(sp)
    80002516:	e822                	sd	s0,16(sp)
    80002518:	e426                	sd	s1,8(sp)
    8000251a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000251c:	00000097          	auipc	ra,0x0
    80002520:	818080e7          	jalr	-2024(ra) # 80001d34 <myproc>
    80002524:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	712080e7          	jalr	1810(ra) # 80000c38 <acquire>
    if (p->state != SLEEPING) {
    8000252e:	4c98                	lw	a4,24(s1)
    80002530:	4789                	li	a5,2
    80002532:	00f70463          	beq	a4,a5,8000253a <yield+0x28>
        p->state = RUNNABLE;  // Only set to RUNNABLE if not sleeping
    80002536:	478d                	li	a5,3
    80002538:	cc9c                	sw	a5,24(s1)
  sched();
    8000253a:	00000097          	auipc	ra,0x0
    8000253e:	f02080e7          	jalr	-254(ra) # 8000243c <sched>
  release(&p->lock);
    80002542:	8526                	mv	a0,s1
    80002544:	ffffe097          	auipc	ra,0xffffe
    80002548:	7a8080e7          	jalr	1960(ra) # 80000cec <release>
}
    8000254c:	60e2                	ld	ra,24(sp)
    8000254e:	6442                	ld	s0,16(sp)
    80002550:	64a2                	ld	s1,8(sp)
    80002552:	6105                	addi	sp,sp,32
    80002554:	8082                	ret

0000000080002556 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002556:	7179                	addi	sp,sp,-48
    80002558:	f406                	sd	ra,40(sp)
    8000255a:	f022                	sd	s0,32(sp)
    8000255c:	ec26                	sd	s1,24(sp)
    8000255e:	e84a                	sd	s2,16(sp)
    80002560:	e44e                	sd	s3,8(sp)
    80002562:	1800                	addi	s0,sp,48
    80002564:	89aa                	mv	s3,a0
    80002566:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002568:	fffff097          	auipc	ra,0xfffff
    8000256c:	7cc080e7          	jalr	1996(ra) # 80001d34 <myproc>
    80002570:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	6c6080e7          	jalr	1734(ra) # 80000c38 <acquire>
  release(lk);
    8000257a:	854a                	mv	a0,s2
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	770080e7          	jalr	1904(ra) # 80000cec <release>

  // Go to sleep.
  p->chan = chan;
    80002584:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002588:	4789                	li	a5,2
    8000258a:	cc9c                	sw	a5,24(s1)
  #ifdef MLFQ
  if(p->is_PQue==1){
    8000258c:	2184a703          	lw	a4,536(s1)
    80002590:	4785                	li	a5,1
    80002592:	02f70963          	beq	a4,a5,800025c4 <sleep+0x6e>
  remProcess(p->CQue_no,p);
  }
  #endif

  sched();
    80002596:	00000097          	auipc	ra,0x0
    8000259a:	ea6080e7          	jalr	-346(ra) # 8000243c <sched>

  // Tidy up.
  p->chan = 0;
    8000259e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	748080e7          	jalr	1864(ra) # 80000cec <release>
  acquire(lk);
    800025ac:	854a                	mv	a0,s2
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	68a080e7          	jalr	1674(ra) # 80000c38 <acquire>
}
    800025b6:	70a2                	ld	ra,40(sp)
    800025b8:	7402                	ld	s0,32(sp)
    800025ba:	64e2                	ld	s1,24(sp)
    800025bc:	6942                	ld	s2,16(sp)
    800025be:	69a2                	ld	s3,8(sp)
    800025c0:	6145                	addi	sp,sp,48
    800025c2:	8082                	ret
  remProcess(p->CQue_no,p);
    800025c4:	85a6                	mv	a1,s1
    800025c6:	2144a503          	lw	a0,532(s1)
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	504080e7          	jalr	1284(ra) # 80001ace <remProcess>
    800025d2:	b7d1                	j	80002596 <sleep+0x40>

00000000800025d4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800025d4:	7139                	addi	sp,sp,-64
    800025d6:	fc06                	sd	ra,56(sp)
    800025d8:	f822                	sd	s0,48(sp)
    800025da:	f426                	sd	s1,40(sp)
    800025dc:	f04a                	sd	s2,32(sp)
    800025de:	ec4e                	sd	s3,24(sp)
    800025e0:	e852                	sd	s4,16(sp)
    800025e2:	e456                	sd	s5,8(sp)
    800025e4:	0080                	addi	s0,sp,64
    800025e6:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025e8:	00012497          	auipc	s1,0x12
    800025ec:	d8848493          	addi	s1,s1,-632 # 80014370 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800025f0:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800025f2:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800025f4:	0001a917          	auipc	s2,0x1a
    800025f8:	77c90913          	addi	s2,s2,1916 # 8001cd70 <tickslock>
    800025fc:	a829                	j	80002616 <wakeup+0x42>
      }
      release(&p->lock);
    800025fe:	8526                	mv	a0,s1
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	6ec080e7          	jalr	1772(ra) # 80000cec <release>
      #ifdef MLFQ
      if(p-> is_PQue== 0){
    80002608:	2184a783          	lw	a5,536(s1)
    8000260c:	cb8d                	beqz	a5,8000263e <wakeup+0x6a>
  for (p = proc; p < &proc[NPROC]; p++)
    8000260e:	22848493          	addi	s1,s1,552
    80002612:	03248e63          	beq	s1,s2,8000264e <wakeup+0x7a>
    if (p != myproc())
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	71e080e7          	jalr	1822(ra) # 80001d34 <myproc>
    8000261e:	fea488e3          	beq	s1,a0,8000260e <wakeup+0x3a>
      acquire(&p->lock);
    80002622:	8526                	mv	a0,s1
    80002624:	ffffe097          	auipc	ra,0xffffe
    80002628:	614080e7          	jalr	1556(ra) # 80000c38 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    8000262c:	4c9c                	lw	a5,24(s1)
    8000262e:	fd3798e3          	bne	a5,s3,800025fe <wakeup+0x2a>
    80002632:	709c                	ld	a5,32(s1)
    80002634:	fd4795e3          	bne	a5,s4,800025fe <wakeup+0x2a>
        p->state = RUNNABLE;
    80002638:	0154ac23          	sw	s5,24(s1)
    8000263c:	b7c9                	j	800025fe <wakeup+0x2a>
      enque_mlfq(p,p->CQue_no);
    8000263e:	2144a583          	lw	a1,532(s1)
    80002642:	8526                	mv	a0,s1
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	30e080e7          	jalr	782(ra) # 80001952 <enque_mlfq>
    8000264c:	b7c9                	j	8000260e <wakeup+0x3a>
      }
      #endif
    }
  }
}
    8000264e:	70e2                	ld	ra,56(sp)
    80002650:	7442                	ld	s0,48(sp)
    80002652:	74a2                	ld	s1,40(sp)
    80002654:	7902                	ld	s2,32(sp)
    80002656:	69e2                	ld	s3,24(sp)
    80002658:	6a42                	ld	s4,16(sp)
    8000265a:	6aa2                	ld	s5,8(sp)
    8000265c:	6121                	addi	sp,sp,64
    8000265e:	8082                	ret

0000000080002660 <reparent>:
{
    80002660:	7179                	addi	sp,sp,-48
    80002662:	f406                	sd	ra,40(sp)
    80002664:	f022                	sd	s0,32(sp)
    80002666:	ec26                	sd	s1,24(sp)
    80002668:	e84a                	sd	s2,16(sp)
    8000266a:	e44e                	sd	s3,8(sp)
    8000266c:	e052                	sd	s4,0(sp)
    8000266e:	1800                	addi	s0,sp,48
    80002670:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002672:	00012497          	auipc	s1,0x12
    80002676:	cfe48493          	addi	s1,s1,-770 # 80014370 <proc>
      pp->parent = initproc;
    8000267a:	00009a17          	auipc	s4,0x9
    8000267e:	e0ea0a13          	addi	s4,s4,-498 # 8000b488 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002682:	0001a997          	auipc	s3,0x1a
    80002686:	6ee98993          	addi	s3,s3,1774 # 8001cd70 <tickslock>
    8000268a:	a029                	j	80002694 <reparent+0x34>
    8000268c:	22848493          	addi	s1,s1,552
    80002690:	01348d63          	beq	s1,s3,800026aa <reparent+0x4a>
    if (pp->parent == p)
    80002694:	7c9c                	ld	a5,56(s1)
    80002696:	ff279be3          	bne	a5,s2,8000268c <reparent+0x2c>
      pp->parent = initproc;
    8000269a:	000a3503          	ld	a0,0(s4)
    8000269e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800026a0:	00000097          	auipc	ra,0x0
    800026a4:	f34080e7          	jalr	-204(ra) # 800025d4 <wakeup>
    800026a8:	b7d5                	j	8000268c <reparent+0x2c>
}
    800026aa:	70a2                	ld	ra,40(sp)
    800026ac:	7402                	ld	s0,32(sp)
    800026ae:	64e2                	ld	s1,24(sp)
    800026b0:	6942                	ld	s2,16(sp)
    800026b2:	69a2                	ld	s3,8(sp)
    800026b4:	6a02                	ld	s4,0(sp)
    800026b6:	6145                	addi	sp,sp,48
    800026b8:	8082                	ret

00000000800026ba <exit>:
{
    800026ba:	7179                	addi	sp,sp,-48
    800026bc:	f406                	sd	ra,40(sp)
    800026be:	f022                	sd	s0,32(sp)
    800026c0:	ec26                	sd	s1,24(sp)
    800026c2:	e84a                	sd	s2,16(sp)
    800026c4:	e44e                	sd	s3,8(sp)
    800026c6:	e052                	sd	s4,0(sp)
    800026c8:	1800                	addi	s0,sp,48
    800026ca:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800026cc:	fffff097          	auipc	ra,0xfffff
    800026d0:	668080e7          	jalr	1640(ra) # 80001d34 <myproc>
    800026d4:	89aa                	mv	s3,a0
  if (p == initproc)
    800026d6:	00009797          	auipc	a5,0x9
    800026da:	db27b783          	ld	a5,-590(a5) # 8000b488 <initproc>
    800026de:	0d050493          	addi	s1,a0,208
    800026e2:	15050913          	addi	s2,a0,336
    800026e6:	02a79363          	bne	a5,a0,8000270c <exit+0x52>
    panic("init exiting");
    800026ea:	00006517          	auipc	a0,0x6
    800026ee:	b7650513          	addi	a0,a0,-1162 # 80008260 <etext+0x260>
    800026f2:	ffffe097          	auipc	ra,0xffffe
    800026f6:	e6e080e7          	jalr	-402(ra) # 80000560 <panic>
      fileclose(f);
    800026fa:	00003097          	auipc	ra,0x3
    800026fe:	89a080e7          	jalr	-1894(ra) # 80004f94 <fileclose>
      p->ofile[fd] = 0;
    80002702:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002706:	04a1                	addi	s1,s1,8
    80002708:	01248563          	beq	s1,s2,80002712 <exit+0x58>
    if (p->ofile[fd])
    8000270c:	6088                	ld	a0,0(s1)
    8000270e:	f575                	bnez	a0,800026fa <exit+0x40>
    80002710:	bfdd                	j	80002706 <exit+0x4c>
  begin_op();
    80002712:	00002097          	auipc	ra,0x2
    80002716:	3b8080e7          	jalr	952(ra) # 80004aca <begin_op>
  iput(p->cwd);
    8000271a:	1509b503          	ld	a0,336(s3)
    8000271e:	00002097          	auipc	ra,0x2
    80002722:	b9c080e7          	jalr	-1124(ra) # 800042ba <iput>
  end_op();
    80002726:	00002097          	auipc	ra,0x2
    8000272a:	41e080e7          	jalr	1054(ra) # 80004b44 <end_op>
  p->cwd = 0;
    8000272e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002732:	00011497          	auipc	s1,0x11
    80002736:	fe648493          	addi	s1,s1,-26 # 80013718 <wait_lock>
    8000273a:	8526                	mv	a0,s1
    8000273c:	ffffe097          	auipc	ra,0xffffe
    80002740:	4fc080e7          	jalr	1276(ra) # 80000c38 <acquire>
  reparent(p);
    80002744:	854e                	mv	a0,s3
    80002746:	00000097          	auipc	ra,0x0
    8000274a:	f1a080e7          	jalr	-230(ra) # 80002660 <reparent>
  wakeup(p->parent);
    8000274e:	0389b503          	ld	a0,56(s3)
    80002752:	00000097          	auipc	ra,0x0
    80002756:	e82080e7          	jalr	-382(ra) # 800025d4 <wakeup>
  acquire(&p->lock);
    8000275a:	854e                	mv	a0,s3
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	4dc080e7          	jalr	1244(ra) # 80000c38 <acquire>
  p->xstate = status;
    80002764:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002768:	4795                	li	a5,5
    8000276a:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    8000276e:	00009797          	auipc	a5,0x9
    80002772:	d227a783          	lw	a5,-734(a5) # 8000b490 <ticks>
    80002776:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    8000277a:	8526                	mv	a0,s1
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	570080e7          	jalr	1392(ra) # 80000cec <release>
  sched();
    80002784:	00000097          	auipc	ra,0x0
    80002788:	cb8080e7          	jalr	-840(ra) # 8000243c <sched>
  panic("zombie exit");
    8000278c:	00006517          	auipc	a0,0x6
    80002790:	ae450513          	addi	a0,a0,-1308 # 80008270 <etext+0x270>
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	dcc080e7          	jalr	-564(ra) # 80000560 <panic>

000000008000279c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000279c:	7179                	addi	sp,sp,-48
    8000279e:	f406                	sd	ra,40(sp)
    800027a0:	f022                	sd	s0,32(sp)
    800027a2:	ec26                	sd	s1,24(sp)
    800027a4:	e84a                	sd	s2,16(sp)
    800027a6:	e44e                	sd	s3,8(sp)
    800027a8:	1800                	addi	s0,sp,48
    800027aa:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800027ac:	00012497          	auipc	s1,0x12
    800027b0:	bc448493          	addi	s1,s1,-1084 # 80014370 <proc>
    800027b4:	0001a997          	auipc	s3,0x1a
    800027b8:	5bc98993          	addi	s3,s3,1468 # 8001cd70 <tickslock>
  {
    acquire(&p->lock);
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	47a080e7          	jalr	1146(ra) # 80000c38 <acquire>
    if (p->pid == pid)
    800027c6:	589c                	lw	a5,48(s1)
    800027c8:	01278d63          	beq	a5,s2,800027e2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027cc:	8526                	mv	a0,s1
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	51e080e7          	jalr	1310(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800027d6:	22848493          	addi	s1,s1,552
    800027da:	ff3491e3          	bne	s1,s3,800027bc <kill+0x20>
  }
  return -1;
    800027de:	557d                	li	a0,-1
    800027e0:	a829                	j	800027fa <kill+0x5e>
      p->killed = 1;
    800027e2:	4785                	li	a5,1
    800027e4:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800027e6:	4c98                	lw	a4,24(s1)
    800027e8:	4789                	li	a5,2
    800027ea:	00f70f63          	beq	a4,a5,80002808 <kill+0x6c>
      release(&p->lock);
    800027ee:	8526                	mv	a0,s1
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	4fc080e7          	jalr	1276(ra) # 80000cec <release>
      return 0;
    800027f8:	4501                	li	a0,0
}
    800027fa:	70a2                	ld	ra,40(sp)
    800027fc:	7402                	ld	s0,32(sp)
    800027fe:	64e2                	ld	s1,24(sp)
    80002800:	6942                	ld	s2,16(sp)
    80002802:	69a2                	ld	s3,8(sp)
    80002804:	6145                	addi	sp,sp,48
    80002806:	8082                	ret
        p->state = RUNNABLE;
    80002808:	478d                	li	a5,3
    8000280a:	cc9c                	sw	a5,24(s1)
    8000280c:	b7cd                	j	800027ee <kill+0x52>

000000008000280e <setkilled>:

void setkilled(struct proc *p)
{
    8000280e:	1101                	addi	sp,sp,-32
    80002810:	ec06                	sd	ra,24(sp)
    80002812:	e822                	sd	s0,16(sp)
    80002814:	e426                	sd	s1,8(sp)
    80002816:	1000                	addi	s0,sp,32
    80002818:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	41e080e7          	jalr	1054(ra) # 80000c38 <acquire>
  p->killed = 1;
    80002822:	4785                	li	a5,1
    80002824:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002826:	8526                	mv	a0,s1
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	4c4080e7          	jalr	1220(ra) # 80000cec <release>
}
    80002830:	60e2                	ld	ra,24(sp)
    80002832:	6442                	ld	s0,16(sp)
    80002834:	64a2                	ld	s1,8(sp)
    80002836:	6105                	addi	sp,sp,32
    80002838:	8082                	ret

000000008000283a <killed>:

int killed(struct proc *p)
{
    8000283a:	1101                	addi	sp,sp,-32
    8000283c:	ec06                	sd	ra,24(sp)
    8000283e:	e822                	sd	s0,16(sp)
    80002840:	e426                	sd	s1,8(sp)
    80002842:	e04a                	sd	s2,0(sp)
    80002844:	1000                	addi	s0,sp,32
    80002846:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	3f0080e7          	jalr	1008(ra) # 80000c38 <acquire>
  k = p->killed;
    80002850:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002854:	8526                	mv	a0,s1
    80002856:	ffffe097          	auipc	ra,0xffffe
    8000285a:	496080e7          	jalr	1174(ra) # 80000cec <release>
  return k;
}
    8000285e:	854a                	mv	a0,s2
    80002860:	60e2                	ld	ra,24(sp)
    80002862:	6442                	ld	s0,16(sp)
    80002864:	64a2                	ld	s1,8(sp)
    80002866:	6902                	ld	s2,0(sp)
    80002868:	6105                	addi	sp,sp,32
    8000286a:	8082                	ret

000000008000286c <wait>:
{
    8000286c:	715d                	addi	sp,sp,-80
    8000286e:	e486                	sd	ra,72(sp)
    80002870:	e0a2                	sd	s0,64(sp)
    80002872:	fc26                	sd	s1,56(sp)
    80002874:	f84a                	sd	s2,48(sp)
    80002876:	f44e                	sd	s3,40(sp)
    80002878:	f052                	sd	s4,32(sp)
    8000287a:	ec56                	sd	s5,24(sp)
    8000287c:	e85a                	sd	s6,16(sp)
    8000287e:	e45e                	sd	s7,8(sp)
    80002880:	e062                	sd	s8,0(sp)
    80002882:	0880                	addi	s0,sp,80
    80002884:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002886:	fffff097          	auipc	ra,0xfffff
    8000288a:	4ae080e7          	jalr	1198(ra) # 80001d34 <myproc>
    8000288e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002890:	00011517          	auipc	a0,0x11
    80002894:	e8850513          	addi	a0,a0,-376 # 80013718 <wait_lock>
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	3a0080e7          	jalr	928(ra) # 80000c38 <acquire>
    havekids = 0;
    800028a0:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800028a2:	4a95                	li	s5,5
        havekids = 1;
    800028a4:	4b05                	li	s6,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800028a6:	0001a997          	auipc	s3,0x1a
    800028aa:	4ca98993          	addi	s3,s3,1226 # 8001cd70 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800028ae:	00011c17          	auipc	s8,0x11
    800028b2:	e6ac0c13          	addi	s8,s8,-406 # 80013718 <wait_lock>
    800028b6:	a8f1                	j	80002992 <wait+0x126>
    800028b8:	17448793          	addi	a5,s1,372
    800028bc:	17490713          	addi	a4,s2,372
    800028c0:	1f048613          	addi	a2,s1,496
            p->syscallCount[i] = pp->syscallCount[i];
    800028c4:	4394                	lw	a3,0(a5)
    800028c6:	c314                	sw	a3,0(a4)
          for (int i = 0; i < NSYSCALLS; i++) {
    800028c8:	0791                	addi	a5,a5,4
    800028ca:	0711                	addi	a4,a4,4
    800028cc:	fec79ce3          	bne	a5,a2,800028c4 <wait+0x58>
          pid = pp->pid;
    800028d0:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800028d4:	000a0e63          	beqz	s4,800028f0 <wait+0x84>
    800028d8:	4691                	li	a3,4
    800028da:	02c48613          	addi	a2,s1,44
    800028de:	85d2                	mv	a1,s4
    800028e0:	05093503          	ld	a0,80(s2)
    800028e4:	fffff097          	auipc	ra,0xfffff
    800028e8:	dfe080e7          	jalr	-514(ra) # 800016e2 <copyout>
    800028ec:	04054163          	bltz	a0,8000292e <wait+0xc2>
          freeproc(pp);
    800028f0:	8526                	mv	a0,s1
    800028f2:	fffff097          	auipc	ra,0xfffff
    800028f6:	5f4080e7          	jalr	1524(ra) # 80001ee6 <freeproc>
          release(&pp->lock);
    800028fa:	8526                	mv	a0,s1
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	3f0080e7          	jalr	1008(ra) # 80000cec <release>
          release(&wait_lock);
    80002904:	00011517          	auipc	a0,0x11
    80002908:	e1450513          	addi	a0,a0,-492 # 80013718 <wait_lock>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	3e0080e7          	jalr	992(ra) # 80000cec <release>
}
    80002914:	854e                	mv	a0,s3
    80002916:	60a6                	ld	ra,72(sp)
    80002918:	6406                	ld	s0,64(sp)
    8000291a:	74e2                	ld	s1,56(sp)
    8000291c:	7942                	ld	s2,48(sp)
    8000291e:	79a2                	ld	s3,40(sp)
    80002920:	7a02                	ld	s4,32(sp)
    80002922:	6ae2                	ld	s5,24(sp)
    80002924:	6b42                	ld	s6,16(sp)
    80002926:	6ba2                	ld	s7,8(sp)
    80002928:	6c02                	ld	s8,0(sp)
    8000292a:	6161                	addi	sp,sp,80
    8000292c:	8082                	ret
            release(&pp->lock);
    8000292e:	8526                	mv	a0,s1
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	3bc080e7          	jalr	956(ra) # 80000cec <release>
            release(&wait_lock);
    80002938:	00011517          	auipc	a0,0x11
    8000293c:	de050513          	addi	a0,a0,-544 # 80013718 <wait_lock>
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	3ac080e7          	jalr	940(ra) # 80000cec <release>
            return -1;
    80002948:	59fd                	li	s3,-1
    8000294a:	b7e9                	j	80002914 <wait+0xa8>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000294c:	22848493          	addi	s1,s1,552
    80002950:	03348463          	beq	s1,s3,80002978 <wait+0x10c>
      if (pp->parent == p)
    80002954:	7c9c                	ld	a5,56(s1)
    80002956:	ff279be3          	bne	a5,s2,8000294c <wait+0xe0>
        acquire(&pp->lock);
    8000295a:	8526                	mv	a0,s1
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	2dc080e7          	jalr	732(ra) # 80000c38 <acquire>
        if (pp->state == ZOMBIE)
    80002964:	4c9c                	lw	a5,24(s1)
    80002966:	f55789e3          	beq	a5,s5,800028b8 <wait+0x4c>
        release(&pp->lock);
    8000296a:	8526                	mv	a0,s1
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	380080e7          	jalr	896(ra) # 80000cec <release>
        havekids = 1;
    80002974:	875a                	mv	a4,s6
    80002976:	bfd9                	j	8000294c <wait+0xe0>
    if (!havekids || killed(p))
    80002978:	c31d                	beqz	a4,8000299e <wait+0x132>
    8000297a:	854a                	mv	a0,s2
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	ebe080e7          	jalr	-322(ra) # 8000283a <killed>
    80002984:	ed09                	bnez	a0,8000299e <wait+0x132>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002986:	85e2                	mv	a1,s8
    80002988:	854a                	mv	a0,s2
    8000298a:	00000097          	auipc	ra,0x0
    8000298e:	bcc080e7          	jalr	-1076(ra) # 80002556 <sleep>
    havekids = 0;
    80002992:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002994:	00012497          	auipc	s1,0x12
    80002998:	9dc48493          	addi	s1,s1,-1572 # 80014370 <proc>
    8000299c:	bf65                	j	80002954 <wait+0xe8>
      release(&wait_lock);
    8000299e:	00011517          	auipc	a0,0x11
    800029a2:	d7a50513          	addi	a0,a0,-646 # 80013718 <wait_lock>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	346080e7          	jalr	838(ra) # 80000cec <release>
      return -1;
    800029ae:	59fd                	li	s3,-1
    800029b0:	b795                	j	80002914 <wait+0xa8>

00000000800029b2 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800029b2:	7179                	addi	sp,sp,-48
    800029b4:	f406                	sd	ra,40(sp)
    800029b6:	f022                	sd	s0,32(sp)
    800029b8:	ec26                	sd	s1,24(sp)
    800029ba:	e84a                	sd	s2,16(sp)
    800029bc:	e44e                	sd	s3,8(sp)
    800029be:	e052                	sd	s4,0(sp)
    800029c0:	1800                	addi	s0,sp,48
    800029c2:	84aa                	mv	s1,a0
    800029c4:	892e                	mv	s2,a1
    800029c6:	89b2                	mv	s3,a2
    800029c8:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800029ca:	fffff097          	auipc	ra,0xfffff
    800029ce:	36a080e7          	jalr	874(ra) # 80001d34 <myproc>
  if (user_dst)
    800029d2:	c08d                	beqz	s1,800029f4 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800029d4:	86d2                	mv	a3,s4
    800029d6:	864e                	mv	a2,s3
    800029d8:	85ca                	mv	a1,s2
    800029da:	6928                	ld	a0,80(a0)
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	d06080e7          	jalr	-762(ra) # 800016e2 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800029e4:	70a2                	ld	ra,40(sp)
    800029e6:	7402                	ld	s0,32(sp)
    800029e8:	64e2                	ld	s1,24(sp)
    800029ea:	6942                	ld	s2,16(sp)
    800029ec:	69a2                	ld	s3,8(sp)
    800029ee:	6a02                	ld	s4,0(sp)
    800029f0:	6145                	addi	sp,sp,48
    800029f2:	8082                	ret
    memmove((char *)dst, src, len);
    800029f4:	000a061b          	sext.w	a2,s4
    800029f8:	85ce                	mv	a1,s3
    800029fa:	854a                	mv	a0,s2
    800029fc:	ffffe097          	auipc	ra,0xffffe
    80002a00:	394080e7          	jalr	916(ra) # 80000d90 <memmove>
    return 0;
    80002a04:	8526                	mv	a0,s1
    80002a06:	bff9                	j	800029e4 <either_copyout+0x32>

0000000080002a08 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002a08:	7179                	addi	sp,sp,-48
    80002a0a:	f406                	sd	ra,40(sp)
    80002a0c:	f022                	sd	s0,32(sp)
    80002a0e:	ec26                	sd	s1,24(sp)
    80002a10:	e84a                	sd	s2,16(sp)
    80002a12:	e44e                	sd	s3,8(sp)
    80002a14:	e052                	sd	s4,0(sp)
    80002a16:	1800                	addi	s0,sp,48
    80002a18:	892a                	mv	s2,a0
    80002a1a:	84ae                	mv	s1,a1
    80002a1c:	89b2                	mv	s3,a2
    80002a1e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a20:	fffff097          	auipc	ra,0xfffff
    80002a24:	314080e7          	jalr	788(ra) # 80001d34 <myproc>
  if (user_src)
    80002a28:	c08d                	beqz	s1,80002a4a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002a2a:	86d2                	mv	a3,s4
    80002a2c:	864e                	mv	a2,s3
    80002a2e:	85ca                	mv	a1,s2
    80002a30:	6928                	ld	a0,80(a0)
    80002a32:	fffff097          	auipc	ra,0xfffff
    80002a36:	d3c080e7          	jalr	-708(ra) # 8000176e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002a3a:	70a2                	ld	ra,40(sp)
    80002a3c:	7402                	ld	s0,32(sp)
    80002a3e:	64e2                	ld	s1,24(sp)
    80002a40:	6942                	ld	s2,16(sp)
    80002a42:	69a2                	ld	s3,8(sp)
    80002a44:	6a02                	ld	s4,0(sp)
    80002a46:	6145                	addi	sp,sp,48
    80002a48:	8082                	ret
    memmove(dst, (char *)src, len);
    80002a4a:	000a061b          	sext.w	a2,s4
    80002a4e:	85ce                	mv	a1,s3
    80002a50:	854a                	mv	a0,s2
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	33e080e7          	jalr	830(ra) # 80000d90 <memmove>
    return 0;
    80002a5a:	8526                	mv	a0,s1
    80002a5c:	bff9                	j	80002a3a <either_copyin+0x32>

0000000080002a5e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002a5e:	715d                	addi	sp,sp,-80
    80002a60:	e486                	sd	ra,72(sp)
    80002a62:	e0a2                	sd	s0,64(sp)
    80002a64:	fc26                	sd	s1,56(sp)
    80002a66:	f84a                	sd	s2,48(sp)
    80002a68:	f44e                	sd	s3,40(sp)
    80002a6a:	f052                	sd	s4,32(sp)
    80002a6c:	ec56                	sd	s5,24(sp)
    80002a6e:	e85a                	sd	s6,16(sp)
    80002a70:	e45e                	sd	s7,8(sp)
    80002a72:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002a74:	00005517          	auipc	a0,0x5
    80002a78:	59c50513          	addi	a0,a0,1436 # 80008010 <etext+0x10>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b2e080e7          	jalr	-1234(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002a84:	00012497          	auipc	s1,0x12
    80002a88:	a4448493          	addi	s1,s1,-1468 # 800144c8 <proc+0x158>
    80002a8c:	0001a917          	auipc	s2,0x1a
    80002a90:	43c90913          	addi	s2,s2,1084 # 8001cec8 <bcache+0x140>
  {
    // printf("PID %d, State %d, Queue %d\n", p->pid, p->state, p->CQue_no);
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a94:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002a96:	00005997          	auipc	s3,0x5
    80002a9a:	7ea98993          	addi	s3,s3,2026 # 80008280 <etext+0x280>
   
    printf("%d %s %s", p->pid, state, p->name);
    80002a9e:	00005a97          	auipc	s5,0x5
    80002aa2:	7eaa8a93          	addi	s5,s5,2026 # 80008288 <etext+0x288>
// #ifdef LBS
//     // Print LBS-specific information (Number of Tickets)
//     printf(" Tickets: %d\n", p->tickets);
//     printf("pid: %d , state :%s,rtime : %d , waittime:%d\n",p->pid,state,p->rtime,p->ctime);
// #endif
    printf("\n");
    80002aa6:	00005a17          	auipc	s4,0x5
    80002aaa:	56aa0a13          	addi	s4,s4,1386 # 80008010 <etext+0x10>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002aae:	00006b97          	auipc	s7,0x6
    80002ab2:	ccab8b93          	addi	s7,s7,-822 # 80008778 <states.0>
    80002ab6:	a00d                	j	80002ad8 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ab8:	ed86a583          	lw	a1,-296(a3)
    80002abc:	8556                	mv	a0,s5
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	aec080e7          	jalr	-1300(ra) # 800005aa <printf>
    printf("\n");
    80002ac6:	8552                	mv	a0,s4
    80002ac8:	ffffe097          	auipc	ra,0xffffe
    80002acc:	ae2080e7          	jalr	-1310(ra) # 800005aa <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ad0:	22848493          	addi	s1,s1,552
    80002ad4:	03248263          	beq	s1,s2,80002af8 <procdump+0x9a>
    if (p->state == UNUSED)
    80002ad8:	86a6                	mv	a3,s1
    80002ada:	ec04a783          	lw	a5,-320(s1)
    80002ade:	dbed                	beqz	a5,80002ad0 <procdump+0x72>
      state = "???";
    80002ae0:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ae2:	fcfb6be3          	bltu	s6,a5,80002ab8 <procdump+0x5a>
    80002ae6:	02079713          	slli	a4,a5,0x20
    80002aea:	01d75793          	srli	a5,a4,0x1d
    80002aee:	97de                	add	a5,a5,s7
    80002af0:	6390                	ld	a2,0(a5)
    80002af2:	f279                	bnez	a2,80002ab8 <procdump+0x5a>
      state = "???";
    80002af4:	864e                	mv	a2,s3
    80002af6:	b7c9                	j	80002ab8 <procdump+0x5a>
  }
}
    80002af8:	60a6                	ld	ra,72(sp)
    80002afa:	6406                	ld	s0,64(sp)
    80002afc:	74e2                	ld	s1,56(sp)
    80002afe:	7942                	ld	s2,48(sp)
    80002b00:	79a2                	ld	s3,40(sp)
    80002b02:	7a02                	ld	s4,32(sp)
    80002b04:	6ae2                	ld	s5,24(sp)
    80002b06:	6b42                	ld	s6,16(sp)
    80002b08:	6ba2                	ld	s7,8(sp)
    80002b0a:	6161                	addi	sp,sp,80
    80002b0c:	8082                	ret

0000000080002b0e <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002b0e:	711d                	addi	sp,sp,-96
    80002b10:	ec86                	sd	ra,88(sp)
    80002b12:	e8a2                	sd	s0,80(sp)
    80002b14:	e4a6                	sd	s1,72(sp)
    80002b16:	e0ca                	sd	s2,64(sp)
    80002b18:	fc4e                	sd	s3,56(sp)
    80002b1a:	f852                	sd	s4,48(sp)
    80002b1c:	f456                	sd	s5,40(sp)
    80002b1e:	f05a                	sd	s6,32(sp)
    80002b20:	ec5e                	sd	s7,24(sp)
    80002b22:	e862                	sd	s8,16(sp)
    80002b24:	e466                	sd	s9,8(sp)
    80002b26:	e06a                	sd	s10,0(sp)
    80002b28:	1080                	addi	s0,sp,96
    80002b2a:	8b2a                	mv	s6,a0
    80002b2c:	8bae                	mv	s7,a1
    80002b2e:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	204080e7          	jalr	516(ra) # 80001d34 <myproc>
    80002b38:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002b3a:	00011517          	auipc	a0,0x11
    80002b3e:	bde50513          	addi	a0,a0,-1058 # 80013718 <wait_lock>
    80002b42:	ffffe097          	auipc	ra,0xffffe
    80002b46:	0f6080e7          	jalr	246(ra) # 80000c38 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002b4a:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002b4c:	4a15                	li	s4,5
        havekids = 1;
    80002b4e:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002b50:	0001a997          	auipc	s3,0x1a
    80002b54:	22098993          	addi	s3,s3,544 # 8001cd70 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002b58:	00011d17          	auipc	s10,0x11
    80002b5c:	bc0d0d13          	addi	s10,s10,-1088 # 80013718 <wait_lock>
    80002b60:	a8e9                	j	80002c3a <waitx+0x12c>
          pid = np->pid;
    80002b62:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002b66:	1684a783          	lw	a5,360(s1)
    80002b6a:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002b6e:	16c4a703          	lw	a4,364(s1)
    80002b72:	9f3d                	addw	a4,a4,a5
    80002b74:	1704a783          	lw	a5,368(s1)
    80002b78:	9f99                	subw	a5,a5,a4
    80002b7a:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002b7e:	000b0e63          	beqz	s6,80002b9a <waitx+0x8c>
    80002b82:	4691                	li	a3,4
    80002b84:	02c48613          	addi	a2,s1,44
    80002b88:	85da                	mv	a1,s6
    80002b8a:	05093503          	ld	a0,80(s2)
    80002b8e:	fffff097          	auipc	ra,0xfffff
    80002b92:	b54080e7          	jalr	-1196(ra) # 800016e2 <copyout>
    80002b96:	04054363          	bltz	a0,80002bdc <waitx+0xce>
          freeproc(np);
    80002b9a:	8526                	mv	a0,s1
    80002b9c:	fffff097          	auipc	ra,0xfffff
    80002ba0:	34a080e7          	jalr	842(ra) # 80001ee6 <freeproc>
          release(&np->lock);
    80002ba4:	8526                	mv	a0,s1
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	146080e7          	jalr	326(ra) # 80000cec <release>
          release(&wait_lock);
    80002bae:	00011517          	auipc	a0,0x11
    80002bb2:	b6a50513          	addi	a0,a0,-1174 # 80013718 <wait_lock>
    80002bb6:	ffffe097          	auipc	ra,0xffffe
    80002bba:	136080e7          	jalr	310(ra) # 80000cec <release>
  }
}
    80002bbe:	854e                	mv	a0,s3
    80002bc0:	60e6                	ld	ra,88(sp)
    80002bc2:	6446                	ld	s0,80(sp)
    80002bc4:	64a6                	ld	s1,72(sp)
    80002bc6:	6906                	ld	s2,64(sp)
    80002bc8:	79e2                	ld	s3,56(sp)
    80002bca:	7a42                	ld	s4,48(sp)
    80002bcc:	7aa2                	ld	s5,40(sp)
    80002bce:	7b02                	ld	s6,32(sp)
    80002bd0:	6be2                	ld	s7,24(sp)
    80002bd2:	6c42                	ld	s8,16(sp)
    80002bd4:	6ca2                	ld	s9,8(sp)
    80002bd6:	6d02                	ld	s10,0(sp)
    80002bd8:	6125                	addi	sp,sp,96
    80002bda:	8082                	ret
            release(&np->lock);
    80002bdc:	8526                	mv	a0,s1
    80002bde:	ffffe097          	auipc	ra,0xffffe
    80002be2:	10e080e7          	jalr	270(ra) # 80000cec <release>
            release(&wait_lock);
    80002be6:	00011517          	auipc	a0,0x11
    80002bea:	b3250513          	addi	a0,a0,-1230 # 80013718 <wait_lock>
    80002bee:	ffffe097          	auipc	ra,0xffffe
    80002bf2:	0fe080e7          	jalr	254(ra) # 80000cec <release>
            return -1;
    80002bf6:	59fd                	li	s3,-1
    80002bf8:	b7d9                	j	80002bbe <waitx+0xb0>
    for (np = proc; np < &proc[NPROC]; np++)
    80002bfa:	22848493          	addi	s1,s1,552
    80002bfe:	03348463          	beq	s1,s3,80002c26 <waitx+0x118>
      if (np->parent == p)
    80002c02:	7c9c                	ld	a5,56(s1)
    80002c04:	ff279be3          	bne	a5,s2,80002bfa <waitx+0xec>
        acquire(&np->lock);
    80002c08:	8526                	mv	a0,s1
    80002c0a:	ffffe097          	auipc	ra,0xffffe
    80002c0e:	02e080e7          	jalr	46(ra) # 80000c38 <acquire>
        if (np->state == ZOMBIE)
    80002c12:	4c9c                	lw	a5,24(s1)
    80002c14:	f54787e3          	beq	a5,s4,80002b62 <waitx+0x54>
        release(&np->lock);
    80002c18:	8526                	mv	a0,s1
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	0d2080e7          	jalr	210(ra) # 80000cec <release>
        havekids = 1;
    80002c22:	8756                	mv	a4,s5
    80002c24:	bfd9                	j	80002bfa <waitx+0xec>
    if (!havekids || p->killed)
    80002c26:	c305                	beqz	a4,80002c46 <waitx+0x138>
    80002c28:	02892783          	lw	a5,40(s2)
    80002c2c:	ef89                	bnez	a5,80002c46 <waitx+0x138>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002c2e:	85ea                	mv	a1,s10
    80002c30:	854a                	mv	a0,s2
    80002c32:	00000097          	auipc	ra,0x0
    80002c36:	924080e7          	jalr	-1756(ra) # 80002556 <sleep>
    havekids = 0;
    80002c3a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002c3c:	00011497          	auipc	s1,0x11
    80002c40:	73448493          	addi	s1,s1,1844 # 80014370 <proc>
    80002c44:	bf7d                	j	80002c02 <waitx+0xf4>
      release(&wait_lock);
    80002c46:	00011517          	auipc	a0,0x11
    80002c4a:	ad250513          	addi	a0,a0,-1326 # 80013718 <wait_lock>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	09e080e7          	jalr	158(ra) # 80000cec <release>
      return -1;
    80002c56:	59fd                	li	s3,-1
    80002c58:	b79d                	j	80002bbe <waitx+0xb0>

0000000080002c5a <update_time>:

void update_time()
{
    80002c5a:	7179                	addi	sp,sp,-48
    80002c5c:	f406                	sd	ra,40(sp)
    80002c5e:	f022                	sd	s0,32(sp)
    80002c60:	ec26                	sd	s1,24(sp)
    80002c62:	e84a                	sd	s2,16(sp)
    80002c64:	e44e                	sd	s3,8(sp)
    80002c66:	e052                	sd	s4,0(sp)
    80002c68:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002c6a:	00011497          	auipc	s1,0x11
    80002c6e:	70648493          	addi	s1,s1,1798 # 80014370 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002c72:	4991                	li	s3,4

      p->RunTime++;

      // printf("Runtime :%d\n",p->RunTime);
    }
    else if(p->state == RUNNABLE){
    80002c74:	4a0d                	li	s4,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002c76:	0001a917          	auipc	s2,0x1a
    80002c7a:	0fa90913          	addi	s2,s2,250 # 8001cd70 <tickslock>
    80002c7e:	a025                	j	80002ca6 <update_time+0x4c>
      p->rtime++;
    80002c80:	1684a783          	lw	a5,360(s1)
    80002c84:	2785                	addiw	a5,a5,1
    80002c86:	16f4a423          	sw	a5,360(s1)
      p->RunTime++;
    80002c8a:	2204a783          	lw	a5,544(s1)
    80002c8e:	2785                	addiw	a5,a5,1
    80002c90:	22f4a023          	sw	a5,544(s1)
      p->WaitTime ++;
    }
    
    release(&p->lock);
    80002c94:	8526                	mv	a0,s1
    80002c96:	ffffe097          	auipc	ra,0xffffe
    80002c9a:	056080e7          	jalr	86(ra) # 80000cec <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002c9e:	22848493          	addi	s1,s1,552
    80002ca2:	03248263          	beq	s1,s2,80002cc6 <update_time+0x6c>
    acquire(&p->lock);
    80002ca6:	8526                	mv	a0,s1
    80002ca8:	ffffe097          	auipc	ra,0xffffe
    80002cac:	f90080e7          	jalr	-112(ra) # 80000c38 <acquire>
    if (p->state == RUNNING)
    80002cb0:	4c9c                	lw	a5,24(s1)
    80002cb2:	fd3787e3          	beq	a5,s3,80002c80 <update_time+0x26>
    else if(p->state == RUNNABLE){
    80002cb6:	fd479fe3          	bne	a5,s4,80002c94 <update_time+0x3a>
      p->WaitTime ++;
    80002cba:	21c4a783          	lw	a5,540(s1)
    80002cbe:	2785                	addiw	a5,a5,1
    80002cc0:	20f4ae23          	sw	a5,540(s1)
    80002cc4:	bfc1                	j	80002c94 <update_time+0x3a>
      printf("GRAPH %d %d %d %d\n", prs->pid, ticks, prs->CQue_no, prs->state);
    }
  }
#endif
  
}
    80002cc6:	70a2                	ld	ra,40(sp)
    80002cc8:	7402                	ld	s0,32(sp)
    80002cca:	64e2                	ld	s1,24(sp)
    80002ccc:	6942                	ld	s2,16(sp)
    80002cce:	69a2                	ld	s3,8(sp)
    80002cd0:	6a02                	ld	s4,0(sp)
    80002cd2:	6145                	addi	sp,sp,48
    80002cd4:	8082                	ret

0000000080002cd6 <swtch>:
    80002cd6:	00153023          	sd	ra,0(a0)
    80002cda:	00253423          	sd	sp,8(a0)
    80002cde:	e900                	sd	s0,16(a0)
    80002ce0:	ed04                	sd	s1,24(a0)
    80002ce2:	03253023          	sd	s2,32(a0)
    80002ce6:	03353423          	sd	s3,40(a0)
    80002cea:	03453823          	sd	s4,48(a0)
    80002cee:	03553c23          	sd	s5,56(a0)
    80002cf2:	05653023          	sd	s6,64(a0)
    80002cf6:	05753423          	sd	s7,72(a0)
    80002cfa:	05853823          	sd	s8,80(a0)
    80002cfe:	05953c23          	sd	s9,88(a0)
    80002d02:	07a53023          	sd	s10,96(a0)
    80002d06:	07b53423          	sd	s11,104(a0)
    80002d0a:	0005b083          	ld	ra,0(a1)
    80002d0e:	0085b103          	ld	sp,8(a1)
    80002d12:	6980                	ld	s0,16(a1)
    80002d14:	6d84                	ld	s1,24(a1)
    80002d16:	0205b903          	ld	s2,32(a1)
    80002d1a:	0285b983          	ld	s3,40(a1)
    80002d1e:	0305ba03          	ld	s4,48(a1)
    80002d22:	0385ba83          	ld	s5,56(a1)
    80002d26:	0405bb03          	ld	s6,64(a1)
    80002d2a:	0485bb83          	ld	s7,72(a1)
    80002d2e:	0505bc03          	ld	s8,80(a1)
    80002d32:	0585bc83          	ld	s9,88(a1)
    80002d36:	0605bd03          	ld	s10,96(a1)
    80002d3a:	0685bd83          	ld	s11,104(a1)
    80002d3e:	8082                	ret

0000000080002d40 <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002d40:	1141                	addi	sp,sp,-16
    80002d42:	e406                	sd	ra,8(sp)
    80002d44:	e022                	sd	s0,0(sp)
    80002d46:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002d48:	00005597          	auipc	a1,0x5
    80002d4c:	58058593          	addi	a1,a1,1408 # 800082c8 <etext+0x2c8>
    80002d50:	0001a517          	auipc	a0,0x1a
    80002d54:	02050513          	addi	a0,a0,32 # 8001cd70 <tickslock>
    80002d58:	ffffe097          	auipc	ra,0xffffe
    80002d5c:	e50080e7          	jalr	-432(ra) # 80000ba8 <initlock>
}
    80002d60:	60a2                	ld	ra,8(sp)
    80002d62:	6402                	ld	s0,0(sp)
    80002d64:	0141                	addi	sp,sp,16
    80002d66:	8082                	ret

0000000080002d68 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002d68:	1141                	addi	sp,sp,-16
    80002d6a:	e422                	sd	s0,8(sp)
    80002d6c:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d6e:	00004797          	auipc	a5,0x4
    80002d72:	92278793          	addi	a5,a5,-1758 # 80006690 <kernelvec>
    80002d76:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002d7a:	6422                	ld	s0,8(sp)
    80002d7c:	0141                	addi	sp,sp,16
    80002d7e:	8082                	ret

0000000080002d80 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002d80:	1141                	addi	sp,sp,-16
    80002d82:	e406                	sd	ra,8(sp)
    80002d84:	e022                	sd	s0,0(sp)
    80002d86:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002d88:	fffff097          	auipc	ra,0xfffff
    80002d8c:	fac080e7          	jalr	-84(ra) # 80001d34 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002d94:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d96:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002d9a:	00004697          	auipc	a3,0x4
    80002d9e:	26668693          	addi	a3,a3,614 # 80007000 <_trampoline>
    80002da2:	00004717          	auipc	a4,0x4
    80002da6:	25e70713          	addi	a4,a4,606 # 80007000 <_trampoline>
    80002daa:	8f15                	sub	a4,a4,a3
    80002dac:	040007b7          	lui	a5,0x4000
    80002db0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002db2:	07b2                	slli	a5,a5,0xc
    80002db4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002db6:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002dba:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002dbc:	18002673          	csrr	a2,satp
    80002dc0:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002dc2:	6d30                	ld	a2,88(a0)
    80002dc4:	6138                	ld	a4,64(a0)
    80002dc6:	6585                	lui	a1,0x1
    80002dc8:	972e                	add	a4,a4,a1
    80002dca:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002dcc:	6d38                	ld	a4,88(a0)
    80002dce:	00000617          	auipc	a2,0x0
    80002dd2:	14660613          	addi	a2,a2,326 # 80002f14 <usertrap>
    80002dd6:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002dd8:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002dda:	8612                	mv	a2,tp
    80002ddc:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002dde:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002de2:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002de6:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dea:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002dee:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002df0:	6f18                	ld	a4,24(a4)
    80002df2:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002df6:	6928                	ld	a0,80(a0)
    80002df8:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002dfa:	00004717          	auipc	a4,0x4
    80002dfe:	2a270713          	addi	a4,a4,674 # 8000709c <userret>
    80002e02:	8f15                	sub	a4,a4,a3
    80002e04:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002e06:	577d                	li	a4,-1
    80002e08:	177e                	slli	a4,a4,0x3f
    80002e0a:	8d59                	or	a0,a0,a4
    80002e0c:	9782                	jalr	a5
}
    80002e0e:	60a2                	ld	ra,8(sp)
    80002e10:	6402                	ld	s0,0(sp)
    80002e12:	0141                	addi	sp,sp,16
    80002e14:	8082                	ret

0000000080002e16 <clockintr>:
}



void clockintr()
{
    80002e16:	1101                	addi	sp,sp,-32
    80002e18:	ec06                	sd	ra,24(sp)
    80002e1a:	e822                	sd	s0,16(sp)
    80002e1c:	e426                	sd	s1,8(sp)
    80002e1e:	e04a                	sd	s2,0(sp)
    80002e20:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002e22:	0001a917          	auipc	s2,0x1a
    80002e26:	f4e90913          	addi	s2,s2,-178 # 8001cd70 <tickslock>
    80002e2a:	854a                	mv	a0,s2
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	e0c080e7          	jalr	-500(ra) # 80000c38 <acquire>
  ticks++;
    80002e34:	00008497          	auipc	s1,0x8
    80002e38:	65c48493          	addi	s1,s1,1628 # 8000b490 <ticks>
    80002e3c:	409c                	lw	a5,0(s1)
    80002e3e:	2785                	addiw	a5,a5,1
    80002e40:	c09c                	sw	a5,0(s1)
  update_time();
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	e18080e7          	jalr	-488(ra) # 80002c5a <update_time>
  //   release(&p->lock);
  // }

 
  
  wakeup(&ticks);
    80002e4a:	8526                	mv	a0,s1
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	788080e7          	jalr	1928(ra) # 800025d4 <wakeup>
  release(&tickslock);
    80002e54:	854a                	mv	a0,s2
    80002e56:	ffffe097          	auipc	ra,0xffffe
    80002e5a:	e96080e7          	jalr	-362(ra) # 80000cec <release>


}
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	64a2                	ld	s1,8(sp)
    80002e64:	6902                	ld	s2,0(sp)
    80002e66:	6105                	addi	sp,sp,32
    80002e68:	8082                	ret

0000000080002e6a <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e6a:	142027f3          	csrr	a5,scause

    return 2;
  }
  else
  {
    return 0;
    80002e6e:	4501                	li	a0,0
  if ((scause & 0x8000000000000000L) &&
    80002e70:	0a07d163          	bgez	a5,80002f12 <devintr+0xa8>
{
    80002e74:	1101                	addi	sp,sp,-32
    80002e76:	ec06                	sd	ra,24(sp)
    80002e78:	e822                	sd	s0,16(sp)
    80002e7a:	1000                	addi	s0,sp,32
      (scause & 0xff) == 9)
    80002e7c:	0ff7f713          	zext.b	a4,a5
  if ((scause & 0x8000000000000000L) &&
    80002e80:	46a5                	li	a3,9
    80002e82:	00d70c63          	beq	a4,a3,80002e9a <devintr+0x30>
  else if (scause == 0x8000000000000001L)
    80002e86:	577d                	li	a4,-1
    80002e88:	177e                	slli	a4,a4,0x3f
    80002e8a:	0705                	addi	a4,a4,1
    return 0;
    80002e8c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002e8e:	06e78163          	beq	a5,a4,80002ef0 <devintr+0x86>
  }
}
    80002e92:	60e2                	ld	ra,24(sp)
    80002e94:	6442                	ld	s0,16(sp)
    80002e96:	6105                	addi	sp,sp,32
    80002e98:	8082                	ret
    80002e9a:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    80002e9c:	00004097          	auipc	ra,0x4
    80002ea0:	900080e7          	jalr	-1792(ra) # 8000679c <plic_claim>
    80002ea4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ea6:	47a9                	li	a5,10
    80002ea8:	00f50963          	beq	a0,a5,80002eba <devintr+0x50>
    else if (irq == VIRTIO0_IRQ)
    80002eac:	4785                	li	a5,1
    80002eae:	00f50b63          	beq	a0,a5,80002ec4 <devintr+0x5a>
    return 1;
    80002eb2:	4505                	li	a0,1
    else if (irq)
    80002eb4:	ec89                	bnez	s1,80002ece <devintr+0x64>
    80002eb6:	64a2                	ld	s1,8(sp)
    80002eb8:	bfe9                	j	80002e92 <devintr+0x28>
      uartintr();
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	b40080e7          	jalr	-1216(ra) # 800009fa <uartintr>
    if (irq)
    80002ec2:	a839                	j	80002ee0 <devintr+0x76>
      virtio_disk_intr();
    80002ec4:	00004097          	auipc	ra,0x4
    80002ec8:	e02080e7          	jalr	-510(ra) # 80006cc6 <virtio_disk_intr>
    if (irq)
    80002ecc:	a811                	j	80002ee0 <devintr+0x76>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ece:	85a6                	mv	a1,s1
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	40050513          	addi	a0,a0,1024 # 800082d0 <etext+0x2d0>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	6d2080e7          	jalr	1746(ra) # 800005aa <printf>
      plic_complete(irq);
    80002ee0:	8526                	mv	a0,s1
    80002ee2:	00004097          	auipc	ra,0x4
    80002ee6:	8de080e7          	jalr	-1826(ra) # 800067c0 <plic_complete>
    return 1;
    80002eea:	4505                	li	a0,1
    80002eec:	64a2                	ld	s1,8(sp)
    80002eee:	b755                	j	80002e92 <devintr+0x28>
    if (cpuid() == 0)
    80002ef0:	fffff097          	auipc	ra,0xfffff
    80002ef4:	e18080e7          	jalr	-488(ra) # 80001d08 <cpuid>
    80002ef8:	c901                	beqz	a0,80002f08 <devintr+0x9e>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002efa:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002efe:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002f00:	14479073          	csrw	sip,a5
    return 2;
    80002f04:	4509                	li	a0,2
    80002f06:	b771                	j	80002e92 <devintr+0x28>
      clockintr();
    80002f08:	00000097          	auipc	ra,0x0
    80002f0c:	f0e080e7          	jalr	-242(ra) # 80002e16 <clockintr>
    80002f10:	b7ed                	j	80002efa <devintr+0x90>
}
    80002f12:	8082                	ret

0000000080002f14 <usertrap>:
{
    80002f14:	7179                	addi	sp,sp,-48
    80002f16:	f406                	sd	ra,40(sp)
    80002f18:	f022                	sd	s0,32(sp)
    80002f1a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f1c:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002f20:	1007f793          	andi	a5,a5,256
    80002f24:	efd1                	bnez	a5,80002fc0 <usertrap+0xac>
    80002f26:	e052                	sd	s4,0(sp)
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f28:	00003797          	auipc	a5,0x3
    80002f2c:	76878793          	addi	a5,a5,1896 # 80006690 <kernelvec>
    80002f30:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	e00080e7          	jalr	-512(ra) # 80001d34 <myproc>
    80002f3c:	8a2a                	mv	s4,a0
  p->trapframe->epc = r_sepc();
    80002f3e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f40:	14102773          	csrr	a4,sepc
    80002f44:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f46:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002f4a:	47a1                	li	a5,8
    80002f4c:	08f70663          	beq	a4,a5,80002fd8 <usertrap+0xc4>
  else if ((which_dev = devintr()) != 0)
    80002f50:	00000097          	auipc	ra,0x0
    80002f54:	f1a080e7          	jalr	-230(ra) # 80002e6a <devintr>
    80002f58:	10050163          	beqz	a0,8000305a <usertrap+0x146>
      if (which_dev == 2 && p->in_alarm == 0)
    80002f5c:	4789                	li	a5,2
    80002f5e:	0af51163          	bne	a0,a5,80003000 <usertrap+0xec>
    80002f62:	ec26                	sd	s1,24(sp)
    80002f64:	e84a                	sd	s2,16(sp)
    80002f66:	e44e                	sd	s3,8(sp)
    80002f68:	208a2783          	lw	a5,520(s4)
    80002f6c:	ef81                	bnez	a5,80002f84 <usertrap+0x70>
        p->alarm_ticks++;
    80002f6e:	1fca2783          	lw	a5,508(s4)
    80002f72:	2785                	addiw	a5,a5,1
    80002f74:	0007871b          	sext.w	a4,a5
    80002f78:	1efa2e23          	sw	a5,508(s4)
        if (p->alarm_ticks == p->alarm_interval)
    80002f7c:	1f8a2783          	lw	a5,504(s4)
    80002f80:	0ae78663          	beq	a5,a4,8000302c <usertrap+0x118>
  if (killed(p))
    80002f84:	8552                	mv	a0,s4
    80002f86:	00000097          	auipc	ra,0x0
    80002f8a:	8b4080e7          	jalr	-1868(ra) # 8000283a <killed>
    80002f8e:	20051463          	bnez	a0,80003196 <usertrap+0x282>
    total_ticks++;
    80002f92:	00008717          	auipc	a4,0x8
    80002f96:	50270713          	addi	a4,a4,1282 # 8000b494 <total_ticks>
    80002f9a:	431c                	lw	a5,0(a4)
    80002f9c:	2785                	addiw	a5,a5,1
    80002f9e:	0007869b          	sext.w	a3,a5
    80002fa2:	c31c                	sw	a5,0(a4)
    if (total_ticks >= priority_boost) {
    80002fa4:	02f00793          	li	a5,47
    80002fa8:	12d7d763          	bge	a5,a3,800030d6 <usertrap+0x1c2>
        for (struct proc *work_proc = proc; work_proc < &proc[NPROC]; work_proc++) {
    80002fac:	00011497          	auipc	s1,0x11
    80002fb0:	3c448493          	addi	s1,s1,964 # 80014370 <proc>
            if (work_proc->state == RUNNABLE || work_proc->state == RUNNING) {
    80002fb4:	4985                	li	s3,1
        for (struct proc *work_proc = proc; work_proc < &proc[NPROC]; work_proc++) {
    80002fb6:	0001a917          	auipc	s2,0x1a
    80002fba:	dba90913          	addi	s2,s2,-582 # 8001cd70 <tickslock>
    80002fbe:	a0c5                	j	8000309e <usertrap+0x18a>
    80002fc0:	ec26                	sd	s1,24(sp)
    80002fc2:	e84a                	sd	s2,16(sp)
    80002fc4:	e44e                	sd	s3,8(sp)
    80002fc6:	e052                	sd	s4,0(sp)
    panic("usertrap: not from user mode");
    80002fc8:	00005517          	auipc	a0,0x5
    80002fcc:	32850513          	addi	a0,a0,808 # 800082f0 <etext+0x2f0>
    80002fd0:	ffffd097          	auipc	ra,0xffffd
    80002fd4:	590080e7          	jalr	1424(ra) # 80000560 <panic>
    if (killed(p))
    80002fd8:	00000097          	auipc	ra,0x0
    80002fdc:	862080e7          	jalr	-1950(ra) # 8000283a <killed>
    80002fe0:	e121                	bnez	a0,80003020 <usertrap+0x10c>
    p->trapframe->epc += 4;
    80002fe2:	058a3703          	ld	a4,88(s4)
    80002fe6:	6f1c                	ld	a5,24(a4)
    80002fe8:	0791                	addi	a5,a5,4
    80002fea:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fec:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002ff0:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ff4:	10079073          	csrw	sstatus,a5
    syscall();
    80002ff8:	00000097          	auipc	ra,0x0
    80002ffc:	400080e7          	jalr	1024(ra) # 800033f8 <syscall>
  if (killed(p))
    80003000:	8552                	mv	a0,s4
    80003002:	00000097          	auipc	ra,0x0
    80003006:	838080e7          	jalr	-1992(ra) # 8000283a <killed>
    8000300a:	18051c63          	bnez	a0,800031a2 <usertrap+0x28e>
  usertrapret();
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	d72080e7          	jalr	-654(ra) # 80002d80 <usertrapret>
    80003016:	6a02                	ld	s4,0(sp)
}
    80003018:	70a2                	ld	ra,40(sp)
    8000301a:	7402                	ld	s0,32(sp)
    8000301c:	6145                	addi	sp,sp,48
    8000301e:	8082                	ret
      exit(-1);
    80003020:	557d                	li	a0,-1
    80003022:	fffff097          	auipc	ra,0xfffff
    80003026:	698080e7          	jalr	1688(ra) # 800026ba <exit>
    8000302a:	bf65                	j	80002fe2 <usertrap+0xce>
          p->in_alarm = 1;
    8000302c:	4785                	li	a5,1
    8000302e:	20fa2423          	sw	a5,520(s4)
          struct trapframe *tf = kalloc();
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	b16080e7          	jalr	-1258(ra) # 80000b48 <kalloc>
    8000303a:	84aa                	mv	s1,a0
          memmove(tf, p->trapframe, PGSIZE);
    8000303c:	6605                	lui	a2,0x1
    8000303e:	058a3583          	ld	a1,88(s4)
    80003042:	ffffe097          	auipc	ra,0xffffe
    80003046:	d4e080e7          	jalr	-690(ra) # 80000d90 <memmove>
          p->alarm_tf = tf;
    8000304a:	209a3023          	sd	s1,512(s4)
          p->trapframe->epc = p->alarm_handler;
    8000304e:	058a3783          	ld	a5,88(s4)
    80003052:	1f0a3703          	ld	a4,496(s4)
    80003056:	ef98                	sd	a4,24(a5)
    80003058:	b735                	j	80002f84 <usertrap+0x70>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000305a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000305e:	030a2603          	lw	a2,48(s4)
    80003062:	00005517          	auipc	a0,0x5
    80003066:	2ae50513          	addi	a0,a0,686 # 80008310 <etext+0x310>
    8000306a:	ffffd097          	auipc	ra,0xffffd
    8000306e:	540080e7          	jalr	1344(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003072:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003076:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000307a:	00005517          	auipc	a0,0x5
    8000307e:	2c650513          	addi	a0,a0,710 # 80008340 <etext+0x340>
    80003082:	ffffd097          	auipc	ra,0xffffd
    80003086:	528080e7          	jalr	1320(ra) # 800005aa <printf>
    setkilled(p);
    8000308a:	8552                	mv	a0,s4
    8000308c:	fffff097          	auipc	ra,0xfffff
    80003090:	782080e7          	jalr	1922(ra) # 8000280e <setkilled>
    80003094:	b7b5                	j	80003000 <usertrap+0xec>
        for (struct proc *work_proc = proc; work_proc < &proc[NPROC]; work_proc++) {
    80003096:	22848493          	addi	s1,s1,552
    8000309a:	03248a63          	beq	s1,s2,800030ce <usertrap+0x1ba>
            if (work_proc->state == RUNNABLE || work_proc->state == RUNNING) {
    8000309e:	4c9c                	lw	a5,24(s1)
    800030a0:	37f5                	addiw	a5,a5,-3
    800030a2:	fef9eae3          	bltu	s3,a5,80003096 <usertrap+0x182>
                remProcess(work_proc->CQue_no, work_proc);  // Remove from current queue
    800030a6:	85a6                	mv	a1,s1
    800030a8:	2144a503          	lw	a0,532(s1)
    800030ac:	fffff097          	auipc	ra,0xfffff
    800030b0:	a22080e7          	jalr	-1502(ra) # 80001ace <remProcess>
                work_proc->CQue_no = 0;  // Move to the highest-priority queue (queue 0)
    800030b4:	2004aa23          	sw	zero,532(s1)
                work_proc->WaitTime= 0;  // Reset wait time
    800030b8:	2004ae23          	sw	zero,540(s1)
                work_proc->RunTime = 0; // reset runtime also 
    800030bc:	2204a023          	sw	zero,544(s1)
                enque_mlfq(work_proc, 0);  // Push back into queue 0
    800030c0:	4581                	li	a1,0
    800030c2:	8526                	mv	a0,s1
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	88e080e7          	jalr	-1906(ra) # 80001952 <enque_mlfq>
    800030cc:	b7e9                	j	80003096 <usertrap+0x182>
        total_ticks = 0;  // Reset the tick counter after boosting
    800030ce:	00008797          	auipc	a5,0x8
    800030d2:	3c07a323          	sw	zero,966(a5) # 8000b494 <total_ticks>
    if(p->RunTime >= mlfq[p->CQue_no].time_slice){
    800030d6:	214a2503          	lw	a0,532(s4)
    800030da:	00551793          	slli	a5,a0,0x5
    800030de:	97aa                	add	a5,a5,a0
    800030e0:	0792                	slli	a5,a5,0x4
    800030e2:	00011717          	auipc	a4,0x11
    800030e6:	a4e70713          	addi	a4,a4,-1458 # 80013b30 <mlfq>
    800030ea:	97ba                	add	a5,a5,a4
    800030ec:	220a2703          	lw	a4,544(s4)
    800030f0:	2087a783          	lw	a5,520(a5)
    800030f4:	04f76663          	bltu	a4,a5,80003140 <usertrap+0x22c>
      if(mlfq[p->CQue_no].tail_ptr > 0){
    800030f8:	00551793          	slli	a5,a0,0x5
    800030fc:	97aa                	add	a5,a5,a0
    800030fe:	0792                	slli	a5,a5,0x4
    80003100:	00011717          	auipc	a4,0x11
    80003104:	a3070713          	addi	a4,a4,-1488 # 80013b30 <mlfq>
    80003108:	97ba                	add	a5,a5,a4
    8000310a:	2047a783          	lw	a5,516(a5)
    8000310e:	04f04363          	bgtz	a5,80003154 <usertrap+0x240>
      if(p->CQue_no < 3){
    80003112:	214a2783          	lw	a5,532(s4)
    80003116:	4709                	li	a4,2
    80003118:	00f74563          	blt	a4,a5,80003122 <usertrap+0x20e>
        p->CQue_no ++;
    8000311c:	2785                	addiw	a5,a5,1
    8000311e:	20fa2a23          	sw	a5,532(s4)
      enque_mlfq(p,p->CQue_no);
    80003122:	214a2583          	lw	a1,532(s4)
    80003126:	8552                	mv	a0,s4
    80003128:	fffff097          	auipc	ra,0xfffff
    8000312c:	82a080e7          	jalr	-2006(ra) # 80001952 <enque_mlfq>
       p->RunTime = 0;
    80003130:	220a2023          	sw	zero,544(s4)
      p->WaitTime = 0;
    80003134:	200a2e23          	sw	zero,540(s4)
      yield();
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	3da080e7          	jalr	986(ra) # 80002512 <yield>
   if(p->CQue_no > 0){
    80003140:	214a2783          	lw	a5,532(s4)
    80003144:	04f05163          	blez	a5,80003186 <usertrap+0x272>
    80003148:	00011497          	auipc	s1,0x11
    8000314c:	9e848493          	addi	s1,s1,-1560 # 80013b30 <mlfq>
      for(int i=0;i<p->CQue_no;i++){
    80003150:	4901                	li	s2,0
    80003152:	a839                	j	80003170 <usertrap+0x25c>
        deque_mlfq(p->CQue_no);
    80003154:	fffff097          	auipc	ra,0xfffff
    80003158:	8dc080e7          	jalr	-1828(ra) # 80001a30 <deque_mlfq>
        p->is_PQue = 0;
    8000315c:	200a2c23          	sw	zero,536(s4)
    80003160:	bf4d                	j	80003112 <usertrap+0x1fe>
      for(int i=0;i<p->CQue_no;i++){
    80003162:	2905                	addiw	s2,s2,1
    80003164:	21048493          	addi	s1,s1,528
    80003168:	214a2783          	lw	a5,532(s4)
    8000316c:	00f95d63          	bge	s2,a5,80003186 <usertrap+0x272>
        if(mlfq[i].tail_ptr != mlfq[i].head_ptr){
    80003170:	2044a703          	lw	a4,516(s1)
    80003174:	2004a783          	lw	a5,512(s1)
    80003178:	fef705e3          	beq	a4,a5,80003162 <usertrap+0x24e>
          yield();
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	396080e7          	jalr	918(ra) # 80002512 <yield>
    80003184:	bff9                	j	80003162 <usertrap+0x24e>
    yield();
    80003186:	fffff097          	auipc	ra,0xfffff
    8000318a:	38c080e7          	jalr	908(ra) # 80002512 <yield>
    8000318e:	64e2                	ld	s1,24(sp)
    80003190:	6942                	ld	s2,16(sp)
    80003192:	69a2                	ld	s3,8(sp)
    80003194:	bdad                	j	8000300e <usertrap+0xfa>
    exit(-1);
    80003196:	557d                	li	a0,-1
    80003198:	fffff097          	auipc	ra,0xfffff
    8000319c:	522080e7          	jalr	1314(ra) # 800026ba <exit>
  if (which_dev == 2){
    800031a0:	bbcd                	j	80002f92 <usertrap+0x7e>
    exit(-1);
    800031a2:	557d                	li	a0,-1
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	516080e7          	jalr	1302(ra) # 800026ba <exit>
  if (which_dev == 2){
    800031ac:	b58d                	j	8000300e <usertrap+0xfa>

00000000800031ae <kerneltrap>:
{
    800031ae:	7179                	addi	sp,sp,-48
    800031b0:	f406                	sd	ra,40(sp)
    800031b2:	f022                	sd	s0,32(sp)
    800031b4:	ec26                	sd	s1,24(sp)
    800031b6:	e84a                	sd	s2,16(sp)
    800031b8:	e44e                	sd	s3,8(sp)
    800031ba:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031bc:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031c0:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031c4:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800031c8:	1004f793          	andi	a5,s1,256
    800031cc:	cb85                	beqz	a5,800031fc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031ce:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031d2:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800031d4:	ef85                	bnez	a5,8000320c <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800031d6:	00000097          	auipc	ra,0x0
    800031da:	c94080e7          	jalr	-876(ra) # 80002e6a <devintr>
    800031de:	cd1d                	beqz	a0,8000321c <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031e0:	4789                	li	a5,2
    800031e2:	06f50a63          	beq	a0,a5,80003256 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031e6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031ea:	10049073          	csrw	sstatus,s1
}
    800031ee:	70a2                	ld	ra,40(sp)
    800031f0:	7402                	ld	s0,32(sp)
    800031f2:	64e2                	ld	s1,24(sp)
    800031f4:	6942                	ld	s2,16(sp)
    800031f6:	69a2                	ld	s3,8(sp)
    800031f8:	6145                	addi	sp,sp,48
    800031fa:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800031fc:	00005517          	auipc	a0,0x5
    80003200:	16450513          	addi	a0,a0,356 # 80008360 <etext+0x360>
    80003204:	ffffd097          	auipc	ra,0xffffd
    80003208:	35c080e7          	jalr	860(ra) # 80000560 <panic>
    panic("kerneltrap: interrupts enabled");
    8000320c:	00005517          	auipc	a0,0x5
    80003210:	17c50513          	addi	a0,a0,380 # 80008388 <etext+0x388>
    80003214:	ffffd097          	auipc	ra,0xffffd
    80003218:	34c080e7          	jalr	844(ra) # 80000560 <panic>
    printf("scause %p\n", scause);
    8000321c:	85ce                	mv	a1,s3
    8000321e:	00005517          	auipc	a0,0x5
    80003222:	18a50513          	addi	a0,a0,394 # 800083a8 <etext+0x3a8>
    80003226:	ffffd097          	auipc	ra,0xffffd
    8000322a:	384080e7          	jalr	900(ra) # 800005aa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000322e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003232:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003236:	00005517          	auipc	a0,0x5
    8000323a:	18250513          	addi	a0,a0,386 # 800083b8 <etext+0x3b8>
    8000323e:	ffffd097          	auipc	ra,0xffffd
    80003242:	36c080e7          	jalr	876(ra) # 800005aa <printf>
    panic("kerneltrap");
    80003246:	00005517          	auipc	a0,0x5
    8000324a:	18a50513          	addi	a0,a0,394 # 800083d0 <etext+0x3d0>
    8000324e:	ffffd097          	auipc	ra,0xffffd
    80003252:	312080e7          	jalr	786(ra) # 80000560 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003256:	fffff097          	auipc	ra,0xfffff
    8000325a:	ade080e7          	jalr	-1314(ra) # 80001d34 <myproc>
    8000325e:	d541                	beqz	a0,800031e6 <kerneltrap+0x38>
    80003260:	fffff097          	auipc	ra,0xfffff
    80003264:	ad4080e7          	jalr	-1324(ra) # 80001d34 <myproc>
    80003268:	4d18                	lw	a4,24(a0)
    8000326a:	4791                	li	a5,4
    8000326c:	f6f71de3          	bne	a4,a5,800031e6 <kerneltrap+0x38>
    yield();
    80003270:	fffff097          	auipc	ra,0xfffff
    80003274:	2a2080e7          	jalr	674(ra) # 80002512 <yield>
    80003278:	b7bd                	j	800031e6 <kerneltrap+0x38>

000000008000327a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000327a:	1101                	addi	sp,sp,-32
    8000327c:	ec06                	sd	ra,24(sp)
    8000327e:	e822                	sd	s0,16(sp)
    80003280:	e426                	sd	s1,8(sp)
    80003282:	1000                	addi	s0,sp,32
    80003284:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003286:	fffff097          	auipc	ra,0xfffff
    8000328a:	aae080e7          	jalr	-1362(ra) # 80001d34 <myproc>
  switch (n) {
    8000328e:	4795                	li	a5,5
    80003290:	0497e163          	bltu	a5,s1,800032d2 <argraw+0x58>
    80003294:	048a                	slli	s1,s1,0x2
    80003296:	00005717          	auipc	a4,0x5
    8000329a:	51270713          	addi	a4,a4,1298 # 800087a8 <states.0+0x30>
    8000329e:	94ba                	add	s1,s1,a4
    800032a0:	409c                	lw	a5,0(s1)
    800032a2:	97ba                	add	a5,a5,a4
    800032a4:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032a6:	6d3c                	ld	a5,88(a0)
    800032a8:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6105                	addi	sp,sp,32
    800032b2:	8082                	ret
    return p->trapframe->a1;
    800032b4:	6d3c                	ld	a5,88(a0)
    800032b6:	7fa8                	ld	a0,120(a5)
    800032b8:	bfcd                	j	800032aa <argraw+0x30>
    return p->trapframe->a2;
    800032ba:	6d3c                	ld	a5,88(a0)
    800032bc:	63c8                	ld	a0,128(a5)
    800032be:	b7f5                	j	800032aa <argraw+0x30>
    return p->trapframe->a3;
    800032c0:	6d3c                	ld	a5,88(a0)
    800032c2:	67c8                	ld	a0,136(a5)
    800032c4:	b7dd                	j	800032aa <argraw+0x30>
    return p->trapframe->a4;
    800032c6:	6d3c                	ld	a5,88(a0)
    800032c8:	6bc8                	ld	a0,144(a5)
    800032ca:	b7c5                	j	800032aa <argraw+0x30>
    return p->trapframe->a5;
    800032cc:	6d3c                	ld	a5,88(a0)
    800032ce:	6fc8                	ld	a0,152(a5)
    800032d0:	bfe9                	j	800032aa <argraw+0x30>
  panic("argraw");
    800032d2:	00005517          	auipc	a0,0x5
    800032d6:	10e50513          	addi	a0,a0,270 # 800083e0 <etext+0x3e0>
    800032da:	ffffd097          	auipc	ra,0xffffd
    800032de:	286080e7          	jalr	646(ra) # 80000560 <panic>

00000000800032e2 <fetchaddr>:
{
    800032e2:	1101                	addi	sp,sp,-32
    800032e4:	ec06                	sd	ra,24(sp)
    800032e6:	e822                	sd	s0,16(sp)
    800032e8:	e426                	sd	s1,8(sp)
    800032ea:	e04a                	sd	s2,0(sp)
    800032ec:	1000                	addi	s0,sp,32
    800032ee:	84aa                	mv	s1,a0
    800032f0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	a42080e7          	jalr	-1470(ra) # 80001d34 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800032fa:	653c                	ld	a5,72(a0)
    800032fc:	02f4f863          	bgeu	s1,a5,8000332c <fetchaddr+0x4a>
    80003300:	00848713          	addi	a4,s1,8
    80003304:	02e7e663          	bltu	a5,a4,80003330 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80003308:	46a1                	li	a3,8
    8000330a:	8626                	mv	a2,s1
    8000330c:	85ca                	mv	a1,s2
    8000330e:	6928                	ld	a0,80(a0)
    80003310:	ffffe097          	auipc	ra,0xffffe
    80003314:	45e080e7          	jalr	1118(ra) # 8000176e <copyin>
    80003318:	00a03533          	snez	a0,a0
    8000331c:	40a00533          	neg	a0,a0
}
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	64a2                	ld	s1,8(sp)
    80003326:	6902                	ld	s2,0(sp)
    80003328:	6105                	addi	sp,sp,32
    8000332a:	8082                	ret
    return -1;
    8000332c:	557d                	li	a0,-1
    8000332e:	bfcd                	j	80003320 <fetchaddr+0x3e>
    80003330:	557d                	li	a0,-1
    80003332:	b7fd                	j	80003320 <fetchaddr+0x3e>

0000000080003334 <fetchstr>:
{
    80003334:	7179                	addi	sp,sp,-48
    80003336:	f406                	sd	ra,40(sp)
    80003338:	f022                	sd	s0,32(sp)
    8000333a:	ec26                	sd	s1,24(sp)
    8000333c:	e84a                	sd	s2,16(sp)
    8000333e:	e44e                	sd	s3,8(sp)
    80003340:	1800                	addi	s0,sp,48
    80003342:	892a                	mv	s2,a0
    80003344:	84ae                	mv	s1,a1
    80003346:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003348:	fffff097          	auipc	ra,0xfffff
    8000334c:	9ec080e7          	jalr	-1556(ra) # 80001d34 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003350:	86ce                	mv	a3,s3
    80003352:	864a                	mv	a2,s2
    80003354:	85a6                	mv	a1,s1
    80003356:	6928                	ld	a0,80(a0)
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	4a4080e7          	jalr	1188(ra) # 800017fc <copyinstr>
    80003360:	00054e63          	bltz	a0,8000337c <fetchstr+0x48>
  return strlen(buf);
    80003364:	8526                	mv	a0,s1
    80003366:	ffffe097          	auipc	ra,0xffffe
    8000336a:	b42080e7          	jalr	-1214(ra) # 80000ea8 <strlen>
}
    8000336e:	70a2                	ld	ra,40(sp)
    80003370:	7402                	ld	s0,32(sp)
    80003372:	64e2                	ld	s1,24(sp)
    80003374:	6942                	ld	s2,16(sp)
    80003376:	69a2                	ld	s3,8(sp)
    80003378:	6145                	addi	sp,sp,48
    8000337a:	8082                	ret
    return -1;
    8000337c:	557d                	li	a0,-1
    8000337e:	bfc5                	j	8000336e <fetchstr+0x3a>

0000000080003380 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003380:	1101                	addi	sp,sp,-32
    80003382:	ec06                	sd	ra,24(sp)
    80003384:	e822                	sd	s0,16(sp)
    80003386:	e426                	sd	s1,8(sp)
    80003388:	1000                	addi	s0,sp,32
    8000338a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	eee080e7          	jalr	-274(ra) # 8000327a <argraw>
    80003394:	c088                	sw	a0,0(s1)
}
    80003396:	60e2                	ld	ra,24(sp)
    80003398:	6442                	ld	s0,16(sp)
    8000339a:	64a2                	ld	s1,8(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    800033aa:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	ece080e7          	jalr	-306(ra) # 8000327a <argraw>
    800033b4:	e088                	sd	a0,0(s1)
}
    800033b6:	60e2                	ld	ra,24(sp)
    800033b8:	6442                	ld	s0,16(sp)
    800033ba:	64a2                	ld	s1,8(sp)
    800033bc:	6105                	addi	sp,sp,32
    800033be:	8082                	ret

00000000800033c0 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033c0:	7179                	addi	sp,sp,-48
    800033c2:	f406                	sd	ra,40(sp)
    800033c4:	f022                	sd	s0,32(sp)
    800033c6:	ec26                	sd	s1,24(sp)
    800033c8:	e84a                	sd	s2,16(sp)
    800033ca:	1800                	addi	s0,sp,48
    800033cc:	84ae                	mv	s1,a1
    800033ce:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800033d0:	fd840593          	addi	a1,s0,-40
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	fcc080e7          	jalr	-52(ra) # 800033a0 <argaddr>
  return fetchstr(addr, buf, max);
    800033dc:	864a                	mv	a2,s2
    800033de:	85a6                	mv	a1,s1
    800033e0:	fd843503          	ld	a0,-40(s0)
    800033e4:	00000097          	auipc	ra,0x0
    800033e8:	f50080e7          	jalr	-176(ra) # 80003334 <fetchstr>
}
    800033ec:	70a2                	ld	ra,40(sp)
    800033ee:	7402                	ld	s0,32(sp)
    800033f0:	64e2                	ld	s1,24(sp)
    800033f2:	6942                	ld	s2,16(sp)
    800033f4:	6145                	addi	sp,sp,48
    800033f6:	8082                	ret

00000000800033f8 <syscall>:
[SYS_settickets] sys_settickets,
};

void
syscall(void)
{
    800033f8:	1101                	addi	sp,sp,-32
    800033fa:	ec06                	sd	ra,24(sp)
    800033fc:	e822                	sd	s0,16(sp)
    800033fe:	e426                	sd	s1,8(sp)
    80003400:	e04a                	sd	s2,0(sp)
    80003402:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80003404:	fffff097          	auipc	ra,0xfffff
    80003408:	930080e7          	jalr	-1744(ra) # 80001d34 <myproc>
    8000340c:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000340e:	05853903          	ld	s2,88(a0)
    80003412:	0a893783          	ld	a5,168(s2)
    80003416:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000341a:	37fd                	addiw	a5,a5,-1
    8000341c:	4765                	li	a4,25
    8000341e:	02f76763          	bltu	a4,a5,8000344c <syscall+0x54>
    80003422:	00369713          	slli	a4,a3,0x3
    80003426:	00005797          	auipc	a5,0x5
    8000342a:	39a78793          	addi	a5,a5,922 # 800087c0 <syscalls>
    8000342e:	97ba                	add	a5,a5,a4
    80003430:	6398                	ld	a4,0(a5)
    80003432:	cf09                	beqz	a4,8000344c <syscall+0x54>
    // printf("num :%d\n",num);
    //  syscall_count[num]++;  
    p->syscallCount[num] ++;
    80003434:	068a                	slli	a3,a3,0x2
    80003436:	00d504b3          	add	s1,a0,a3
    8000343a:	1744a783          	lw	a5,372(s1)
    8000343e:	2785                	addiw	a5,a5,1
    80003440:	16f4aa23          	sw	a5,372(s1)
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003444:	9702                	jalr	a4
    80003446:	06a93823          	sd	a0,112(s2)
    8000344a:	a839                	j	80003468 <syscall+0x70>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000344c:	15848613          	addi	a2,s1,344
    80003450:	588c                	lw	a1,48(s1)
    80003452:	00005517          	auipc	a0,0x5
    80003456:	f9650513          	addi	a0,a0,-106 # 800083e8 <etext+0x3e8>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	150080e7          	jalr	336(ra) # 800005aa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003462:	6cbc                	ld	a5,88(s1)
    80003464:	577d                	li	a4,-1
    80003466:	fbb8                	sd	a4,112(a5)
  }
}
    80003468:	60e2                	ld	ra,24(sp)
    8000346a:	6442                	ld	s0,16(sp)
    8000346c:	64a2                	ld	s1,8(sp)
    8000346e:	6902                	ld	s2,0(sp)
    80003470:	6105                	addi	sp,sp,32
    80003472:	8082                	ret

0000000080003474 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003474:	1101                	addi	sp,sp,-32
    80003476:	ec06                	sd	ra,24(sp)
    80003478:	e822                	sd	s0,16(sp)
    8000347a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000347c:	fec40593          	addi	a1,s0,-20
    80003480:	4501                	li	a0,0
    80003482:	00000097          	auipc	ra,0x0
    80003486:	efe080e7          	jalr	-258(ra) # 80003380 <argint>
  exit(n);
    8000348a:	fec42503          	lw	a0,-20(s0)
    8000348e:	fffff097          	auipc	ra,0xfffff
    80003492:	22c080e7          	jalr	556(ra) # 800026ba <exit>
  return 0; // not reached
}
    80003496:	4501                	li	a0,0
    80003498:	60e2                	ld	ra,24(sp)
    8000349a:	6442                	ld	s0,16(sp)
    8000349c:	6105                	addi	sp,sp,32
    8000349e:	8082                	ret

00000000800034a0 <sys_getpid>:

uint64
sys_getpid(void)
{
    800034a0:	1141                	addi	sp,sp,-16
    800034a2:	e406                	sd	ra,8(sp)
    800034a4:	e022                	sd	s0,0(sp)
    800034a6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800034a8:	fffff097          	auipc	ra,0xfffff
    800034ac:	88c080e7          	jalr	-1908(ra) # 80001d34 <myproc>
}
    800034b0:	5908                	lw	a0,48(a0)
    800034b2:	60a2                	ld	ra,8(sp)
    800034b4:	6402                	ld	s0,0(sp)
    800034b6:	0141                	addi	sp,sp,16
    800034b8:	8082                	ret

00000000800034ba <sys_fork>:

uint64
sys_fork(void)
{
    800034ba:	1141                	addi	sp,sp,-16
    800034bc:	e406                	sd	ra,8(sp)
    800034be:	e022                	sd	s0,0(sp)
    800034c0:	0800                	addi	s0,sp,16
  return fork();
    800034c2:	fffff097          	auipc	ra,0xfffff
    800034c6:	c58080e7          	jalr	-936(ra) # 8000211a <fork>
}
    800034ca:	60a2                	ld	ra,8(sp)
    800034cc:	6402                	ld	s0,0(sp)
    800034ce:	0141                	addi	sp,sp,16
    800034d0:	8082                	ret

00000000800034d2 <sys_wait>:

uint64
sys_wait(void)
{
    800034d2:	1101                	addi	sp,sp,-32
    800034d4:	ec06                	sd	ra,24(sp)
    800034d6:	e822                	sd	s0,16(sp)
    800034d8:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800034da:	fe840593          	addi	a1,s0,-24
    800034de:	4501                	li	a0,0
    800034e0:	00000097          	auipc	ra,0x0
    800034e4:	ec0080e7          	jalr	-320(ra) # 800033a0 <argaddr>
  return wait(p);
    800034e8:	fe843503          	ld	a0,-24(s0)
    800034ec:	fffff097          	auipc	ra,0xfffff
    800034f0:	380080e7          	jalr	896(ra) # 8000286c <wait>
}
    800034f4:	60e2                	ld	ra,24(sp)
    800034f6:	6442                	ld	s0,16(sp)
    800034f8:	6105                	addi	sp,sp,32
    800034fa:	8082                	ret

00000000800034fc <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800034fc:	7179                	addi	sp,sp,-48
    800034fe:	f406                	sd	ra,40(sp)
    80003500:	f022                	sd	s0,32(sp)
    80003502:	ec26                	sd	s1,24(sp)
    80003504:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003506:	fdc40593          	addi	a1,s0,-36
    8000350a:	4501                	li	a0,0
    8000350c:	00000097          	auipc	ra,0x0
    80003510:	e74080e7          	jalr	-396(ra) # 80003380 <argint>
  addr = myproc()->sz;
    80003514:	fffff097          	auipc	ra,0xfffff
    80003518:	820080e7          	jalr	-2016(ra) # 80001d34 <myproc>
    8000351c:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000351e:	fdc42503          	lw	a0,-36(s0)
    80003522:	fffff097          	auipc	ra,0xfffff
    80003526:	b9c080e7          	jalr	-1124(ra) # 800020be <growproc>
    8000352a:	00054863          	bltz	a0,8000353a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000352e:	8526                	mv	a0,s1
    80003530:	70a2                	ld	ra,40(sp)
    80003532:	7402                	ld	s0,32(sp)
    80003534:	64e2                	ld	s1,24(sp)
    80003536:	6145                	addi	sp,sp,48
    80003538:	8082                	ret
    return -1;
    8000353a:	54fd                	li	s1,-1
    8000353c:	bfcd                	j	8000352e <sys_sbrk+0x32>

000000008000353e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000353e:	7139                	addi	sp,sp,-64
    80003540:	fc06                	sd	ra,56(sp)
    80003542:	f822                	sd	s0,48(sp)
    80003544:	f04a                	sd	s2,32(sp)
    80003546:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003548:	fcc40593          	addi	a1,s0,-52
    8000354c:	4501                	li	a0,0
    8000354e:	00000097          	auipc	ra,0x0
    80003552:	e32080e7          	jalr	-462(ra) # 80003380 <argint>
  acquire(&tickslock);
    80003556:	0001a517          	auipc	a0,0x1a
    8000355a:	81a50513          	addi	a0,a0,-2022 # 8001cd70 <tickslock>
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	6da080e7          	jalr	1754(ra) # 80000c38 <acquire>
  ticks0 = ticks;
    80003566:	00008917          	auipc	s2,0x8
    8000356a:	f2a92903          	lw	s2,-214(s2) # 8000b490 <ticks>
  while (ticks - ticks0 < n)
    8000356e:	fcc42783          	lw	a5,-52(s0)
    80003572:	c3b9                	beqz	a5,800035b8 <sys_sleep+0x7a>
    80003574:	f426                	sd	s1,40(sp)
    80003576:	ec4e                	sd	s3,24(sp)
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003578:	00019997          	auipc	s3,0x19
    8000357c:	7f898993          	addi	s3,s3,2040 # 8001cd70 <tickslock>
    80003580:	00008497          	auipc	s1,0x8
    80003584:	f1048493          	addi	s1,s1,-240 # 8000b490 <ticks>
    if (killed(myproc()))
    80003588:	ffffe097          	auipc	ra,0xffffe
    8000358c:	7ac080e7          	jalr	1964(ra) # 80001d34 <myproc>
    80003590:	fffff097          	auipc	ra,0xfffff
    80003594:	2aa080e7          	jalr	682(ra) # 8000283a <killed>
    80003598:	ed15                	bnez	a0,800035d4 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    8000359a:	85ce                	mv	a1,s3
    8000359c:	8526                	mv	a0,s1
    8000359e:	fffff097          	auipc	ra,0xfffff
    800035a2:	fb8080e7          	jalr	-72(ra) # 80002556 <sleep>
  while (ticks - ticks0 < n)
    800035a6:	409c                	lw	a5,0(s1)
    800035a8:	412787bb          	subw	a5,a5,s2
    800035ac:	fcc42703          	lw	a4,-52(s0)
    800035b0:	fce7ece3          	bltu	a5,a4,80003588 <sys_sleep+0x4a>
    800035b4:	74a2                	ld	s1,40(sp)
    800035b6:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    800035b8:	00019517          	auipc	a0,0x19
    800035bc:	7b850513          	addi	a0,a0,1976 # 8001cd70 <tickslock>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	72c080e7          	jalr	1836(ra) # 80000cec <release>
  return 0;
    800035c8:	4501                	li	a0,0
}
    800035ca:	70e2                	ld	ra,56(sp)
    800035cc:	7442                	ld	s0,48(sp)
    800035ce:	7902                	ld	s2,32(sp)
    800035d0:	6121                	addi	sp,sp,64
    800035d2:	8082                	ret
      release(&tickslock);
    800035d4:	00019517          	auipc	a0,0x19
    800035d8:	79c50513          	addi	a0,a0,1948 # 8001cd70 <tickslock>
    800035dc:	ffffd097          	auipc	ra,0xffffd
    800035e0:	710080e7          	jalr	1808(ra) # 80000cec <release>
      return -1;
    800035e4:	557d                	li	a0,-1
    800035e6:	74a2                	ld	s1,40(sp)
    800035e8:	69e2                	ld	s3,24(sp)
    800035ea:	b7c5                	j	800035ca <sys_sleep+0x8c>

00000000800035ec <sys_kill>:

uint64
sys_kill(void)
{
    800035ec:	1101                	addi	sp,sp,-32
    800035ee:	ec06                	sd	ra,24(sp)
    800035f0:	e822                	sd	s0,16(sp)
    800035f2:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800035f4:	fec40593          	addi	a1,s0,-20
    800035f8:	4501                	li	a0,0
    800035fa:	00000097          	auipc	ra,0x0
    800035fe:	d86080e7          	jalr	-634(ra) # 80003380 <argint>
  return kill(pid);
    80003602:	fec42503          	lw	a0,-20(s0)
    80003606:	fffff097          	auipc	ra,0xfffff
    8000360a:	196080e7          	jalr	406(ra) # 8000279c <kill>
}
    8000360e:	60e2                	ld	ra,24(sp)
    80003610:	6442                	ld	s0,16(sp)
    80003612:	6105                	addi	sp,sp,32
    80003614:	8082                	ret

0000000080003616 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003616:	1101                	addi	sp,sp,-32
    80003618:	ec06                	sd	ra,24(sp)
    8000361a:	e822                	sd	s0,16(sp)
    8000361c:	e426                	sd	s1,8(sp)
    8000361e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003620:	00019517          	auipc	a0,0x19
    80003624:	75050513          	addi	a0,a0,1872 # 8001cd70 <tickslock>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	610080e7          	jalr	1552(ra) # 80000c38 <acquire>
  xticks = ticks;
    80003630:	00008497          	auipc	s1,0x8
    80003634:	e604a483          	lw	s1,-416(s1) # 8000b490 <ticks>
  release(&tickslock);
    80003638:	00019517          	auipc	a0,0x19
    8000363c:	73850513          	addi	a0,a0,1848 # 8001cd70 <tickslock>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	6ac080e7          	jalr	1708(ra) # 80000cec <release>
  return xticks;
}
    80003648:	02049513          	slli	a0,s1,0x20
    8000364c:	9101                	srli	a0,a0,0x20
    8000364e:	60e2                	ld	ra,24(sp)
    80003650:	6442                	ld	s0,16(sp)
    80003652:	64a2                	ld	s1,8(sp)
    80003654:	6105                	addi	sp,sp,32
    80003656:	8082                	ret

0000000080003658 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003658:	7139                	addi	sp,sp,-64
    8000365a:	fc06                	sd	ra,56(sp)
    8000365c:	f822                	sd	s0,48(sp)
    8000365e:	f426                	sd	s1,40(sp)
    80003660:	f04a                	sd	s2,32(sp)
    80003662:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003664:	fd840593          	addi	a1,s0,-40
    80003668:	4501                	li	a0,0
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	d36080e7          	jalr	-714(ra) # 800033a0 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003672:	fd040593          	addi	a1,s0,-48
    80003676:	4505                	li	a0,1
    80003678:	00000097          	auipc	ra,0x0
    8000367c:	d28080e7          	jalr	-728(ra) # 800033a0 <argaddr>
  argaddr(2, &addr2);
    80003680:	fc840593          	addi	a1,s0,-56
    80003684:	4509                	li	a0,2
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	d1a080e7          	jalr	-742(ra) # 800033a0 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    8000368e:	fc040613          	addi	a2,s0,-64
    80003692:	fc440593          	addi	a1,s0,-60
    80003696:	fd843503          	ld	a0,-40(s0)
    8000369a:	fffff097          	auipc	ra,0xfffff
    8000369e:	474080e7          	jalr	1140(ra) # 80002b0e <waitx>
    800036a2:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800036a4:	ffffe097          	auipc	ra,0xffffe
    800036a8:	690080e7          	jalr	1680(ra) # 80001d34 <myproc>
    800036ac:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036ae:	4691                	li	a3,4
    800036b0:	fc440613          	addi	a2,s0,-60
    800036b4:	fd043583          	ld	a1,-48(s0)
    800036b8:	6928                	ld	a0,80(a0)
    800036ba:	ffffe097          	auipc	ra,0xffffe
    800036be:	028080e7          	jalr	40(ra) # 800016e2 <copyout>
    return -1;
    800036c2:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800036c4:	00054f63          	bltz	a0,800036e2 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800036c8:	4691                	li	a3,4
    800036ca:	fc040613          	addi	a2,s0,-64
    800036ce:	fc843583          	ld	a1,-56(s0)
    800036d2:	68a8                	ld	a0,80(s1)
    800036d4:	ffffe097          	auipc	ra,0xffffe
    800036d8:	00e080e7          	jalr	14(ra) # 800016e2 <copyout>
    800036dc:	00054a63          	bltz	a0,800036f0 <sys_waitx+0x98>
    return -1;
  return ret;
    800036e0:	87ca                	mv	a5,s2
}
    800036e2:	853e                	mv	a0,a5
    800036e4:	70e2                	ld	ra,56(sp)
    800036e6:	7442                	ld	s0,48(sp)
    800036e8:	74a2                	ld	s1,40(sp)
    800036ea:	7902                	ld	s2,32(sp)
    800036ec:	6121                	addi	sp,sp,64
    800036ee:	8082                	ret
    return -1;
    800036f0:	57fd                	li	a5,-1
    800036f2:	bfc5                	j	800036e2 <sys_waitx+0x8a>

00000000800036f4 <sys_getSysCount>:



uint64 sys_getSysCount(void) {
    800036f4:	1101                	addi	sp,sp,-32
    800036f6:	ec06                	sd	ra,24(sp)
    800036f8:	e822                	sd	s0,16(sp)
    800036fa:	1000                	addi	s0,sp,32
    int mask;
    argint(0, &mask);
    800036fc:	fec40593          	addi	a1,s0,-20
    80003700:	4501                	li	a0,0
    80003702:	00000097          	auipc	ra,0x0
    80003706:	c7e080e7          	jalr	-898(ra) # 80003380 <argint>

    int syscall_num = 0;
    struct proc*p = myproc();
    8000370a:	ffffe097          	auipc	ra,0xffffe
    8000370e:	62a080e7          	jalr	1578(ra) # 80001d34 <myproc>
    80003712:	862a                	mv	a2,a0

    if (mask == 0) {
    80003714:	fec42783          	lw	a5,-20(s0)
        return -1; // Invalid mask
    80003718:	557d                	li	a0,-1
    if (mask == 0) {
    8000371a:	c785                	beqz	a5,80003742 <sys_getSysCount+0x4e>
    }
    while ((mask & 1) == 0) {  // Check the least significant bit
    8000371c:	0017f713          	andi	a4,a5,1
    80003720:	e70d                	bnez	a4,8000374a <sys_getSysCount+0x56>
        syscall_num++;
    80003722:	2705                	addiw	a4,a4,1
        mask >>= 1;
    80003724:	4017d79b          	sraiw	a5,a5,0x1
    while ((mask & 1) == 0) {  // Check the least significant bit
    80003728:	0017f693          	andi	a3,a5,1
    8000372c:	dafd                	beqz	a3,80003722 <sys_getSysCount+0x2e>
    }

    if (syscall_num >= 31)  // Handle invalid syscall number
    8000372e:	47f9                	li	a5,30
        return -1;
    80003730:	557d                	li	a0,-1
    if (syscall_num >= 31)  // Handle invalid syscall number
    80003732:	00e7c863          	blt	a5,a4,80003742 <sys_getSysCount+0x4e>
    return p->syscallCount[syscall_num];
    80003736:	05c70713          	addi	a4,a4,92
    8000373a:	070a                	slli	a4,a4,0x2
    8000373c:	00e60533          	add	a0,a2,a4
    80003740:	4148                	lw	a0,4(a0)
 
}
    80003742:	60e2                	ld	ra,24(sp)
    80003744:	6442                	ld	s0,16(sp)
    80003746:	6105                	addi	sp,sp,32
    80003748:	8082                	ret
    int syscall_num = 0;
    8000374a:	4701                	li	a4,0
    8000374c:	b7ed                	j	80003736 <sys_getSysCount+0x42>

000000008000374e <sys_sigalarm>:


uint64 sys_sigalarm(void)
{
    8000374e:	1101                	addi	sp,sp,-32
    80003750:	ec06                	sd	ra,24(sp)
    80003752:	e822                	sd	s0,16(sp)
    80003754:	1000                	addi	s0,sp,32
  

  uint64 handler_addr;
  int interval;

  argint(0, &interval);
    80003756:	fe440593          	addi	a1,s0,-28
    8000375a:	4501                	li	a0,0
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	c24080e7          	jalr	-988(ra) # 80003380 <argint>
  argaddr(1, &handler_addr);
    80003764:	fe840593          	addi	a1,s0,-24
    80003768:	4505                	li	a0,1
    8000376a:	00000097          	auipc	ra,0x0
    8000376e:	c36080e7          	jalr	-970(ra) # 800033a0 <argaddr>

  struct proc*p = myproc();
    80003772:	ffffe097          	auipc	ra,0xffffe
    80003776:	5c2080e7          	jalr	1474(ra) # 80001d34 <myproc>

  p->alarm_ticks = 0;
    8000377a:	1e052e23          	sw	zero,508(a0)
  p->alarm_interval = interval;
    8000377e:	fe442783          	lw	a5,-28(s0)
    80003782:	1ef52c23          	sw	a5,504(a0)
  p->alarm_handler = handler_addr;
    80003786:	fe843783          	ld	a5,-24(s0)
    8000378a:	1ef53823          	sd	a5,496(a0)
  p->in_alarm = 0;
    8000378e:	20052423          	sw	zero,520(a0)

  return 0;
}
    80003792:	4501                	li	a0,0
    80003794:	60e2                	ld	ra,24(sp)
    80003796:	6442                	ld	s0,16(sp)
    80003798:	6105                	addi	sp,sp,32
    8000379a:	8082                	ret

000000008000379c <sys_sigreturn>:

uint64 sys_sigreturn(void)
{
    8000379c:	1101                	addi	sp,sp,-32
    8000379e:	ec06                	sd	ra,24(sp)
    800037a0:	e822                	sd	s0,16(sp)
    800037a2:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800037a4:	ffffe097          	auipc	ra,0xffffe
    800037a8:	590080e7          	jalr	1424(ra) # 80001d34 <myproc>
  
  if(p->in_alarm == 1){
    800037ac:	20852703          	lw	a4,520(a0)
    800037b0:	4785                	li	a5,1
    800037b2:	00f70763          	beq	a4,a5,800037c0 <sys_sigreturn+0x24>
    p->alarm_tf = 0;
    p->in_alarm = 0;
    p->alarm_ticks = 0;
  }
  return 0;
}
    800037b6:	4501                	li	a0,0
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	6105                	addi	sp,sp,32
    800037be:	8082                	ret
    800037c0:	e426                	sd	s1,8(sp)
    800037c2:	84aa                	mv	s1,a0
    memmove(p->trapframe, p->alarm_tf, PGSIZE);
    800037c4:	6605                	lui	a2,0x1
    800037c6:	20053583          	ld	a1,512(a0)
    800037ca:	6d28                	ld	a0,88(a0)
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	5c4080e7          	jalr	1476(ra) # 80000d90 <memmove>
    kfree(p->alarm_tf);
    800037d4:	2004b503          	ld	a0,512(s1)
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	272080e7          	jalr	626(ra) # 80000a4a <kfree>
    p->alarm_tf = 0;
    800037e0:	2004b023          	sd	zero,512(s1)
    p->in_alarm = 0;
    800037e4:	2004a423          	sw	zero,520(s1)
    p->alarm_ticks = 0;
    800037e8:	1e04ae23          	sw	zero,508(s1)
    800037ec:	64a2                	ld	s1,8(sp)
    800037ee:	b7e1                	j	800037b6 <sys_sigreturn+0x1a>

00000000800037f0 <sys_settickets>:

uint64 sys_settickets(void){
    800037f0:	1101                	addi	sp,sp,-32
    800037f2:	ec06                	sd	ra,24(sp)
    800037f4:	e822                	sd	s0,16(sp)
    800037f6:	1000                	addi	s0,sp,32
  int num;
  argint(0,&num);
    800037f8:	fec40593          	addi	a1,s0,-20
    800037fc:	4501                	li	a0,0
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	b82080e7          	jalr	-1150(ra) # 80003380 <argint>

  struct proc* p = myproc();
    80003806:	ffffe097          	auipc	ra,0xffffe
    8000380a:	52e080e7          	jalr	1326(ra) # 80001d34 <myproc>
    8000380e:	87aa                	mv	a5,a0
  if(num <= 0){
    80003810:	fec42603          	lw	a2,-20(s0)
    return -1;
    80003814:	557d                	li	a0,-1
  if(num <= 0){
    80003816:	00c05e63          	blez	a2,80003832 <sys_settickets+0x42>
  }
  p->tickets = num;
    8000381a:	20c7a623          	sw	a2,524(a5)
  printf("pid :%d - tickets: %d\n",p->pid,p->tickets);
    8000381e:	5b8c                	lw	a1,48(a5)
    80003820:	00005517          	auipc	a0,0x5
    80003824:	be850513          	addi	a0,a0,-1048 # 80008408 <etext+0x408>
    80003828:	ffffd097          	auipc	ra,0xffffd
    8000382c:	d82080e7          	jalr	-638(ra) # 800005aa <printf>

  return 0;
    80003830:	4501                	li	a0,0


}
    80003832:	60e2                	ld	ra,24(sp)
    80003834:	6442                	ld	s0,16(sp)
    80003836:	6105                	addi	sp,sp,32
    80003838:	8082                	ret

000000008000383a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000383a:	7179                	addi	sp,sp,-48
    8000383c:	f406                	sd	ra,40(sp)
    8000383e:	f022                	sd	s0,32(sp)
    80003840:	ec26                	sd	s1,24(sp)
    80003842:	e84a                	sd	s2,16(sp)
    80003844:	e44e                	sd	s3,8(sp)
    80003846:	e052                	sd	s4,0(sp)
    80003848:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000384a:	00005597          	auipc	a1,0x5
    8000384e:	bd658593          	addi	a1,a1,-1066 # 80008420 <etext+0x420>
    80003852:	00019517          	auipc	a0,0x19
    80003856:	53650513          	addi	a0,a0,1334 # 8001cd88 <bcache>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	34e080e7          	jalr	846(ra) # 80000ba8 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003862:	00021797          	auipc	a5,0x21
    80003866:	52678793          	addi	a5,a5,1318 # 80024d88 <bcache+0x8000>
    8000386a:	00021717          	auipc	a4,0x21
    8000386e:	78670713          	addi	a4,a4,1926 # 80024ff0 <bcache+0x8268>
    80003872:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003876:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000387a:	00019497          	auipc	s1,0x19
    8000387e:	52648493          	addi	s1,s1,1318 # 8001cda0 <bcache+0x18>
    b->next = bcache.head.next;
    80003882:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003884:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003886:	00005a17          	auipc	s4,0x5
    8000388a:	ba2a0a13          	addi	s4,s4,-1118 # 80008428 <etext+0x428>
    b->next = bcache.head.next;
    8000388e:	2b893783          	ld	a5,696(s2)
    80003892:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003894:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003898:	85d2                	mv	a1,s4
    8000389a:	01048513          	addi	a0,s1,16
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	4e8080e7          	jalr	1256(ra) # 80004d86 <initsleeplock>
    bcache.head.next->prev = b;
    800038a6:	2b893783          	ld	a5,696(s2)
    800038aa:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800038ac:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800038b0:	45848493          	addi	s1,s1,1112
    800038b4:	fd349de3          	bne	s1,s3,8000388e <binit+0x54>
  }
}
    800038b8:	70a2                	ld	ra,40(sp)
    800038ba:	7402                	ld	s0,32(sp)
    800038bc:	64e2                	ld	s1,24(sp)
    800038be:	6942                	ld	s2,16(sp)
    800038c0:	69a2                	ld	s3,8(sp)
    800038c2:	6a02                	ld	s4,0(sp)
    800038c4:	6145                	addi	sp,sp,48
    800038c6:	8082                	ret

00000000800038c8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800038c8:	7179                	addi	sp,sp,-48
    800038ca:	f406                	sd	ra,40(sp)
    800038cc:	f022                	sd	s0,32(sp)
    800038ce:	ec26                	sd	s1,24(sp)
    800038d0:	e84a                	sd	s2,16(sp)
    800038d2:	e44e                	sd	s3,8(sp)
    800038d4:	1800                	addi	s0,sp,48
    800038d6:	892a                	mv	s2,a0
    800038d8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800038da:	00019517          	auipc	a0,0x19
    800038de:	4ae50513          	addi	a0,a0,1198 # 8001cd88 <bcache>
    800038e2:	ffffd097          	auipc	ra,0xffffd
    800038e6:	356080e7          	jalr	854(ra) # 80000c38 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800038ea:	00021497          	auipc	s1,0x21
    800038ee:	7564b483          	ld	s1,1878(s1) # 80025040 <bcache+0x82b8>
    800038f2:	00021797          	auipc	a5,0x21
    800038f6:	6fe78793          	addi	a5,a5,1790 # 80024ff0 <bcache+0x8268>
    800038fa:	02f48f63          	beq	s1,a5,80003938 <bread+0x70>
    800038fe:	873e                	mv	a4,a5
    80003900:	a021                	j	80003908 <bread+0x40>
    80003902:	68a4                	ld	s1,80(s1)
    80003904:	02e48a63          	beq	s1,a4,80003938 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003908:	449c                	lw	a5,8(s1)
    8000390a:	ff279ce3          	bne	a5,s2,80003902 <bread+0x3a>
    8000390e:	44dc                	lw	a5,12(s1)
    80003910:	ff3799e3          	bne	a5,s3,80003902 <bread+0x3a>
      b->refcnt++;
    80003914:	40bc                	lw	a5,64(s1)
    80003916:	2785                	addiw	a5,a5,1
    80003918:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000391a:	00019517          	auipc	a0,0x19
    8000391e:	46e50513          	addi	a0,a0,1134 # 8001cd88 <bcache>
    80003922:	ffffd097          	auipc	ra,0xffffd
    80003926:	3ca080e7          	jalr	970(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    8000392a:	01048513          	addi	a0,s1,16
    8000392e:	00001097          	auipc	ra,0x1
    80003932:	492080e7          	jalr	1170(ra) # 80004dc0 <acquiresleep>
      return b;
    80003936:	a8b9                	j	80003994 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003938:	00021497          	auipc	s1,0x21
    8000393c:	7004b483          	ld	s1,1792(s1) # 80025038 <bcache+0x82b0>
    80003940:	00021797          	auipc	a5,0x21
    80003944:	6b078793          	addi	a5,a5,1712 # 80024ff0 <bcache+0x8268>
    80003948:	00f48863          	beq	s1,a5,80003958 <bread+0x90>
    8000394c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000394e:	40bc                	lw	a5,64(s1)
    80003950:	cf81                	beqz	a5,80003968 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003952:	64a4                	ld	s1,72(s1)
    80003954:	fee49de3          	bne	s1,a4,8000394e <bread+0x86>
  panic("bget: no buffers");
    80003958:	00005517          	auipc	a0,0x5
    8000395c:	ad850513          	addi	a0,a0,-1320 # 80008430 <etext+0x430>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	c00080e7          	jalr	-1024(ra) # 80000560 <panic>
      b->dev = dev;
    80003968:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000396c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003970:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003974:	4785                	li	a5,1
    80003976:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003978:	00019517          	auipc	a0,0x19
    8000397c:	41050513          	addi	a0,a0,1040 # 8001cd88 <bcache>
    80003980:	ffffd097          	auipc	ra,0xffffd
    80003984:	36c080e7          	jalr	876(ra) # 80000cec <release>
      acquiresleep(&b->lock);
    80003988:	01048513          	addi	a0,s1,16
    8000398c:	00001097          	auipc	ra,0x1
    80003990:	434080e7          	jalr	1076(ra) # 80004dc0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003994:	409c                	lw	a5,0(s1)
    80003996:	cb89                	beqz	a5,800039a8 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003998:	8526                	mv	a0,s1
    8000399a:	70a2                	ld	ra,40(sp)
    8000399c:	7402                	ld	s0,32(sp)
    8000399e:	64e2                	ld	s1,24(sp)
    800039a0:	6942                	ld	s2,16(sp)
    800039a2:	69a2                	ld	s3,8(sp)
    800039a4:	6145                	addi	sp,sp,48
    800039a6:	8082                	ret
    virtio_disk_rw(b, 0);
    800039a8:	4581                	li	a1,0
    800039aa:	8526                	mv	a0,s1
    800039ac:	00003097          	auipc	ra,0x3
    800039b0:	0ec080e7          	jalr	236(ra) # 80006a98 <virtio_disk_rw>
    b->valid = 1;
    800039b4:	4785                	li	a5,1
    800039b6:	c09c                	sw	a5,0(s1)
  return b;
    800039b8:	b7c5                	j	80003998 <bread+0xd0>

00000000800039ba <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800039ba:	1101                	addi	sp,sp,-32
    800039bc:	ec06                	sd	ra,24(sp)
    800039be:	e822                	sd	s0,16(sp)
    800039c0:	e426                	sd	s1,8(sp)
    800039c2:	1000                	addi	s0,sp,32
    800039c4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800039c6:	0541                	addi	a0,a0,16
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	492080e7          	jalr	1170(ra) # 80004e5a <holdingsleep>
    800039d0:	cd01                	beqz	a0,800039e8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800039d2:	4585                	li	a1,1
    800039d4:	8526                	mv	a0,s1
    800039d6:	00003097          	auipc	ra,0x3
    800039da:	0c2080e7          	jalr	194(ra) # 80006a98 <virtio_disk_rw>
}
    800039de:	60e2                	ld	ra,24(sp)
    800039e0:	6442                	ld	s0,16(sp)
    800039e2:	64a2                	ld	s1,8(sp)
    800039e4:	6105                	addi	sp,sp,32
    800039e6:	8082                	ret
    panic("bwrite");
    800039e8:	00005517          	auipc	a0,0x5
    800039ec:	a6050513          	addi	a0,a0,-1440 # 80008448 <etext+0x448>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	b70080e7          	jalr	-1168(ra) # 80000560 <panic>

00000000800039f8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800039f8:	1101                	addi	sp,sp,-32
    800039fa:	ec06                	sd	ra,24(sp)
    800039fc:	e822                	sd	s0,16(sp)
    800039fe:	e426                	sd	s1,8(sp)
    80003a00:	e04a                	sd	s2,0(sp)
    80003a02:	1000                	addi	s0,sp,32
    80003a04:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003a06:	01050913          	addi	s2,a0,16
    80003a0a:	854a                	mv	a0,s2
    80003a0c:	00001097          	auipc	ra,0x1
    80003a10:	44e080e7          	jalr	1102(ra) # 80004e5a <holdingsleep>
    80003a14:	c925                	beqz	a0,80003a84 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003a16:	854a                	mv	a0,s2
    80003a18:	00001097          	auipc	ra,0x1
    80003a1c:	3fe080e7          	jalr	1022(ra) # 80004e16 <releasesleep>

  acquire(&bcache.lock);
    80003a20:	00019517          	auipc	a0,0x19
    80003a24:	36850513          	addi	a0,a0,872 # 8001cd88 <bcache>
    80003a28:	ffffd097          	auipc	ra,0xffffd
    80003a2c:	210080e7          	jalr	528(ra) # 80000c38 <acquire>
  b->refcnt--;
    80003a30:	40bc                	lw	a5,64(s1)
    80003a32:	37fd                	addiw	a5,a5,-1
    80003a34:	0007871b          	sext.w	a4,a5
    80003a38:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003a3a:	e71d                	bnez	a4,80003a68 <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003a3c:	68b8                	ld	a4,80(s1)
    80003a3e:	64bc                	ld	a5,72(s1)
    80003a40:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003a42:	68b8                	ld	a4,80(s1)
    80003a44:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003a46:	00021797          	auipc	a5,0x21
    80003a4a:	34278793          	addi	a5,a5,834 # 80024d88 <bcache+0x8000>
    80003a4e:	2b87b703          	ld	a4,696(a5)
    80003a52:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003a54:	00021717          	auipc	a4,0x21
    80003a58:	59c70713          	addi	a4,a4,1436 # 80024ff0 <bcache+0x8268>
    80003a5c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003a5e:	2b87b703          	ld	a4,696(a5)
    80003a62:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003a64:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003a68:	00019517          	auipc	a0,0x19
    80003a6c:	32050513          	addi	a0,a0,800 # 8001cd88 <bcache>
    80003a70:	ffffd097          	auipc	ra,0xffffd
    80003a74:	27c080e7          	jalr	636(ra) # 80000cec <release>
}
    80003a78:	60e2                	ld	ra,24(sp)
    80003a7a:	6442                	ld	s0,16(sp)
    80003a7c:	64a2                	ld	s1,8(sp)
    80003a7e:	6902                	ld	s2,0(sp)
    80003a80:	6105                	addi	sp,sp,32
    80003a82:	8082                	ret
    panic("brelse");
    80003a84:	00005517          	auipc	a0,0x5
    80003a88:	9cc50513          	addi	a0,a0,-1588 # 80008450 <etext+0x450>
    80003a8c:	ffffd097          	auipc	ra,0xffffd
    80003a90:	ad4080e7          	jalr	-1324(ra) # 80000560 <panic>

0000000080003a94 <bpin>:

void
bpin(struct buf *b) {
    80003a94:	1101                	addi	sp,sp,-32
    80003a96:	ec06                	sd	ra,24(sp)
    80003a98:	e822                	sd	s0,16(sp)
    80003a9a:	e426                	sd	s1,8(sp)
    80003a9c:	1000                	addi	s0,sp,32
    80003a9e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003aa0:	00019517          	auipc	a0,0x19
    80003aa4:	2e850513          	addi	a0,a0,744 # 8001cd88 <bcache>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	190080e7          	jalr	400(ra) # 80000c38 <acquire>
  b->refcnt++;
    80003ab0:	40bc                	lw	a5,64(s1)
    80003ab2:	2785                	addiw	a5,a5,1
    80003ab4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003ab6:	00019517          	auipc	a0,0x19
    80003aba:	2d250513          	addi	a0,a0,722 # 8001cd88 <bcache>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	22e080e7          	jalr	558(ra) # 80000cec <release>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6105                	addi	sp,sp,32
    80003ace:	8082                	ret

0000000080003ad0 <bunpin>:

void
bunpin(struct buf *b) {
    80003ad0:	1101                	addi	sp,sp,-32
    80003ad2:	ec06                	sd	ra,24(sp)
    80003ad4:	e822                	sd	s0,16(sp)
    80003ad6:	e426                	sd	s1,8(sp)
    80003ad8:	1000                	addi	s0,sp,32
    80003ada:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003adc:	00019517          	auipc	a0,0x19
    80003ae0:	2ac50513          	addi	a0,a0,684 # 8001cd88 <bcache>
    80003ae4:	ffffd097          	auipc	ra,0xffffd
    80003ae8:	154080e7          	jalr	340(ra) # 80000c38 <acquire>
  b->refcnt--;
    80003aec:	40bc                	lw	a5,64(s1)
    80003aee:	37fd                	addiw	a5,a5,-1
    80003af0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003af2:	00019517          	auipc	a0,0x19
    80003af6:	29650513          	addi	a0,a0,662 # 8001cd88 <bcache>
    80003afa:	ffffd097          	auipc	ra,0xffffd
    80003afe:	1f2080e7          	jalr	498(ra) # 80000cec <release>
}
    80003b02:	60e2                	ld	ra,24(sp)
    80003b04:	6442                	ld	s0,16(sp)
    80003b06:	64a2                	ld	s1,8(sp)
    80003b08:	6105                	addi	sp,sp,32
    80003b0a:	8082                	ret

0000000080003b0c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003b0c:	1101                	addi	sp,sp,-32
    80003b0e:	ec06                	sd	ra,24(sp)
    80003b10:	e822                	sd	s0,16(sp)
    80003b12:	e426                	sd	s1,8(sp)
    80003b14:	e04a                	sd	s2,0(sp)
    80003b16:	1000                	addi	s0,sp,32
    80003b18:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003b1a:	00d5d59b          	srliw	a1,a1,0xd
    80003b1e:	00022797          	auipc	a5,0x22
    80003b22:	9467a783          	lw	a5,-1722(a5) # 80025464 <sb+0x1c>
    80003b26:	9dbd                	addw	a1,a1,a5
    80003b28:	00000097          	auipc	ra,0x0
    80003b2c:	da0080e7          	jalr	-608(ra) # 800038c8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003b30:	0074f713          	andi	a4,s1,7
    80003b34:	4785                	li	a5,1
    80003b36:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003b3a:	14ce                	slli	s1,s1,0x33
    80003b3c:	90d9                	srli	s1,s1,0x36
    80003b3e:	00950733          	add	a4,a0,s1
    80003b42:	05874703          	lbu	a4,88(a4)
    80003b46:	00e7f6b3          	and	a3,a5,a4
    80003b4a:	c69d                	beqz	a3,80003b78 <bfree+0x6c>
    80003b4c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003b4e:	94aa                	add	s1,s1,a0
    80003b50:	fff7c793          	not	a5,a5
    80003b54:	8f7d                	and	a4,a4,a5
    80003b56:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003b5a:	00001097          	auipc	ra,0x1
    80003b5e:	148080e7          	jalr	328(ra) # 80004ca2 <log_write>
  brelse(bp);
    80003b62:	854a                	mv	a0,s2
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	e94080e7          	jalr	-364(ra) # 800039f8 <brelse>
}
    80003b6c:	60e2                	ld	ra,24(sp)
    80003b6e:	6442                	ld	s0,16(sp)
    80003b70:	64a2                	ld	s1,8(sp)
    80003b72:	6902                	ld	s2,0(sp)
    80003b74:	6105                	addi	sp,sp,32
    80003b76:	8082                	ret
    panic("freeing free block");
    80003b78:	00005517          	auipc	a0,0x5
    80003b7c:	8e050513          	addi	a0,a0,-1824 # 80008458 <etext+0x458>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	9e0080e7          	jalr	-1568(ra) # 80000560 <panic>

0000000080003b88 <balloc>:
{
    80003b88:	711d                	addi	sp,sp,-96
    80003b8a:	ec86                	sd	ra,88(sp)
    80003b8c:	e8a2                	sd	s0,80(sp)
    80003b8e:	e4a6                	sd	s1,72(sp)
    80003b90:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003b92:	00022797          	auipc	a5,0x22
    80003b96:	8ba7a783          	lw	a5,-1862(a5) # 8002544c <sb+0x4>
    80003b9a:	10078f63          	beqz	a5,80003cb8 <balloc+0x130>
    80003b9e:	e0ca                	sd	s2,64(sp)
    80003ba0:	fc4e                	sd	s3,56(sp)
    80003ba2:	f852                	sd	s4,48(sp)
    80003ba4:	f456                	sd	s5,40(sp)
    80003ba6:	f05a                	sd	s6,32(sp)
    80003ba8:	ec5e                	sd	s7,24(sp)
    80003baa:	e862                	sd	s8,16(sp)
    80003bac:	e466                	sd	s9,8(sp)
    80003bae:	8baa                	mv	s7,a0
    80003bb0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003bb2:	00022b17          	auipc	s6,0x22
    80003bb6:	896b0b13          	addi	s6,s6,-1898 # 80025448 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bba:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003bbc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003bbe:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003bc0:	6c89                	lui	s9,0x2
    80003bc2:	a061                	j	80003c4a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003bc4:	97ca                	add	a5,a5,s2
    80003bc6:	8e55                	or	a2,a2,a3
    80003bc8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003bcc:	854a                	mv	a0,s2
    80003bce:	00001097          	auipc	ra,0x1
    80003bd2:	0d4080e7          	jalr	212(ra) # 80004ca2 <log_write>
        brelse(bp);
    80003bd6:	854a                	mv	a0,s2
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	e20080e7          	jalr	-480(ra) # 800039f8 <brelse>
  bp = bread(dev, bno);
    80003be0:	85a6                	mv	a1,s1
    80003be2:	855e                	mv	a0,s7
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	ce4080e7          	jalr	-796(ra) # 800038c8 <bread>
    80003bec:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003bee:	40000613          	li	a2,1024
    80003bf2:	4581                	li	a1,0
    80003bf4:	05850513          	addi	a0,a0,88
    80003bf8:	ffffd097          	auipc	ra,0xffffd
    80003bfc:	13c080e7          	jalr	316(ra) # 80000d34 <memset>
  log_write(bp);
    80003c00:	854a                	mv	a0,s2
    80003c02:	00001097          	auipc	ra,0x1
    80003c06:	0a0080e7          	jalr	160(ra) # 80004ca2 <log_write>
  brelse(bp);
    80003c0a:	854a                	mv	a0,s2
    80003c0c:	00000097          	auipc	ra,0x0
    80003c10:	dec080e7          	jalr	-532(ra) # 800039f8 <brelse>
}
    80003c14:	6906                	ld	s2,64(sp)
    80003c16:	79e2                	ld	s3,56(sp)
    80003c18:	7a42                	ld	s4,48(sp)
    80003c1a:	7aa2                	ld	s5,40(sp)
    80003c1c:	7b02                	ld	s6,32(sp)
    80003c1e:	6be2                	ld	s7,24(sp)
    80003c20:	6c42                	ld	s8,16(sp)
    80003c22:	6ca2                	ld	s9,8(sp)
}
    80003c24:	8526                	mv	a0,s1
    80003c26:	60e6                	ld	ra,88(sp)
    80003c28:	6446                	ld	s0,80(sp)
    80003c2a:	64a6                	ld	s1,72(sp)
    80003c2c:	6125                	addi	sp,sp,96
    80003c2e:	8082                	ret
    brelse(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	dc6080e7          	jalr	-570(ra) # 800039f8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003c3a:	015c87bb          	addw	a5,s9,s5
    80003c3e:	00078a9b          	sext.w	s5,a5
    80003c42:	004b2703          	lw	a4,4(s6)
    80003c46:	06eaf163          	bgeu	s5,a4,80003ca8 <balloc+0x120>
    bp = bread(dev, BBLOCK(b, sb));
    80003c4a:	41fad79b          	sraiw	a5,s5,0x1f
    80003c4e:	0137d79b          	srliw	a5,a5,0x13
    80003c52:	015787bb          	addw	a5,a5,s5
    80003c56:	40d7d79b          	sraiw	a5,a5,0xd
    80003c5a:	01cb2583          	lw	a1,28(s6)
    80003c5e:	9dbd                	addw	a1,a1,a5
    80003c60:	855e                	mv	a0,s7
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	c66080e7          	jalr	-922(ra) # 800038c8 <bread>
    80003c6a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c6c:	004b2503          	lw	a0,4(s6)
    80003c70:	000a849b          	sext.w	s1,s5
    80003c74:	8762                	mv	a4,s8
    80003c76:	faa4fde3          	bgeu	s1,a0,80003c30 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003c7a:	00777693          	andi	a3,a4,7
    80003c7e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003c82:	41f7579b          	sraiw	a5,a4,0x1f
    80003c86:	01d7d79b          	srliw	a5,a5,0x1d
    80003c8a:	9fb9                	addw	a5,a5,a4
    80003c8c:	4037d79b          	sraiw	a5,a5,0x3
    80003c90:	00f90633          	add	a2,s2,a5
    80003c94:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003c98:	00c6f5b3          	and	a1,a3,a2
    80003c9c:	d585                	beqz	a1,80003bc4 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003c9e:	2705                	addiw	a4,a4,1
    80003ca0:	2485                	addiw	s1,s1,1
    80003ca2:	fd471ae3          	bne	a4,s4,80003c76 <balloc+0xee>
    80003ca6:	b769                	j	80003c30 <balloc+0xa8>
    80003ca8:	6906                	ld	s2,64(sp)
    80003caa:	79e2                	ld	s3,56(sp)
    80003cac:	7a42                	ld	s4,48(sp)
    80003cae:	7aa2                	ld	s5,40(sp)
    80003cb0:	7b02                	ld	s6,32(sp)
    80003cb2:	6be2                	ld	s7,24(sp)
    80003cb4:	6c42                	ld	s8,16(sp)
    80003cb6:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003cb8:	00004517          	auipc	a0,0x4
    80003cbc:	7b850513          	addi	a0,a0,1976 # 80008470 <etext+0x470>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	8ea080e7          	jalr	-1814(ra) # 800005aa <printf>
  return 0;
    80003cc8:	4481                	li	s1,0
    80003cca:	bfa9                	j	80003c24 <balloc+0x9c>

0000000080003ccc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003ccc:	7179                	addi	sp,sp,-48
    80003cce:	f406                	sd	ra,40(sp)
    80003cd0:	f022                	sd	s0,32(sp)
    80003cd2:	ec26                	sd	s1,24(sp)
    80003cd4:	e84a                	sd	s2,16(sp)
    80003cd6:	e44e                	sd	s3,8(sp)
    80003cd8:	1800                	addi	s0,sp,48
    80003cda:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003cdc:	47ad                	li	a5,11
    80003cde:	02b7e863          	bltu	a5,a1,80003d0e <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003ce2:	02059793          	slli	a5,a1,0x20
    80003ce6:	01e7d593          	srli	a1,a5,0x1e
    80003cea:	00b504b3          	add	s1,a0,a1
    80003cee:	0504a903          	lw	s2,80(s1)
    80003cf2:	08091263          	bnez	s2,80003d76 <bmap+0xaa>
      addr = balloc(ip->dev);
    80003cf6:	4108                	lw	a0,0(a0)
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	e90080e7          	jalr	-368(ra) # 80003b88 <balloc>
    80003d00:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003d04:	06090963          	beqz	s2,80003d76 <bmap+0xaa>
        return 0;
      ip->addrs[bn] = addr;
    80003d08:	0524a823          	sw	s2,80(s1)
    80003d0c:	a0ad                	j	80003d76 <bmap+0xaa>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003d0e:	ff45849b          	addiw	s1,a1,-12
    80003d12:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003d16:	0ff00793          	li	a5,255
    80003d1a:	08e7e863          	bltu	a5,a4,80003daa <bmap+0xde>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003d1e:	08052903          	lw	s2,128(a0)
    80003d22:	00091f63          	bnez	s2,80003d40 <bmap+0x74>
      addr = balloc(ip->dev);
    80003d26:	4108                	lw	a0,0(a0)
    80003d28:	00000097          	auipc	ra,0x0
    80003d2c:	e60080e7          	jalr	-416(ra) # 80003b88 <balloc>
    80003d30:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003d34:	04090163          	beqz	s2,80003d76 <bmap+0xaa>
    80003d38:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003d3a:	0929a023          	sw	s2,128(s3)
    80003d3e:	a011                	j	80003d42 <bmap+0x76>
    80003d40:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003d42:	85ca                	mv	a1,s2
    80003d44:	0009a503          	lw	a0,0(s3)
    80003d48:	00000097          	auipc	ra,0x0
    80003d4c:	b80080e7          	jalr	-1152(ra) # 800038c8 <bread>
    80003d50:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003d52:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003d56:	02049713          	slli	a4,s1,0x20
    80003d5a:	01e75593          	srli	a1,a4,0x1e
    80003d5e:	00b784b3          	add	s1,a5,a1
    80003d62:	0004a903          	lw	s2,0(s1)
    80003d66:	02090063          	beqz	s2,80003d86 <bmap+0xba>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003d6a:	8552                	mv	a0,s4
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	c8c080e7          	jalr	-884(ra) # 800039f8 <brelse>
    return addr;
    80003d74:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80003d76:	854a                	mv	a0,s2
    80003d78:	70a2                	ld	ra,40(sp)
    80003d7a:	7402                	ld	s0,32(sp)
    80003d7c:	64e2                	ld	s1,24(sp)
    80003d7e:	6942                	ld	s2,16(sp)
    80003d80:	69a2                	ld	s3,8(sp)
    80003d82:	6145                	addi	sp,sp,48
    80003d84:	8082                	ret
      addr = balloc(ip->dev);
    80003d86:	0009a503          	lw	a0,0(s3)
    80003d8a:	00000097          	auipc	ra,0x0
    80003d8e:	dfe080e7          	jalr	-514(ra) # 80003b88 <balloc>
    80003d92:	0005091b          	sext.w	s2,a0
      if(addr){
    80003d96:	fc090ae3          	beqz	s2,80003d6a <bmap+0x9e>
        a[bn] = addr;
    80003d9a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003d9e:	8552                	mv	a0,s4
    80003da0:	00001097          	auipc	ra,0x1
    80003da4:	f02080e7          	jalr	-254(ra) # 80004ca2 <log_write>
    80003da8:	b7c9                	j	80003d6a <bmap+0x9e>
    80003daa:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80003dac:	00004517          	auipc	a0,0x4
    80003db0:	6dc50513          	addi	a0,a0,1756 # 80008488 <etext+0x488>
    80003db4:	ffffc097          	auipc	ra,0xffffc
    80003db8:	7ac080e7          	jalr	1964(ra) # 80000560 <panic>

0000000080003dbc <iget>:
{
    80003dbc:	7179                	addi	sp,sp,-48
    80003dbe:	f406                	sd	ra,40(sp)
    80003dc0:	f022                	sd	s0,32(sp)
    80003dc2:	ec26                	sd	s1,24(sp)
    80003dc4:	e84a                	sd	s2,16(sp)
    80003dc6:	e44e                	sd	s3,8(sp)
    80003dc8:	e052                	sd	s4,0(sp)
    80003dca:	1800                	addi	s0,sp,48
    80003dcc:	89aa                	mv	s3,a0
    80003dce:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003dd0:	00021517          	auipc	a0,0x21
    80003dd4:	69850513          	addi	a0,a0,1688 # 80025468 <itable>
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	e60080e7          	jalr	-416(ra) # 80000c38 <acquire>
  empty = 0;
    80003de0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003de2:	00021497          	auipc	s1,0x21
    80003de6:	69e48493          	addi	s1,s1,1694 # 80025480 <itable+0x18>
    80003dea:	00023697          	auipc	a3,0x23
    80003dee:	12668693          	addi	a3,a3,294 # 80026f10 <log>
    80003df2:	a039                	j	80003e00 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003df4:	02090b63          	beqz	s2,80003e2a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003df8:	08848493          	addi	s1,s1,136
    80003dfc:	02d48a63          	beq	s1,a3,80003e30 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003e00:	449c                	lw	a5,8(s1)
    80003e02:	fef059e3          	blez	a5,80003df4 <iget+0x38>
    80003e06:	4098                	lw	a4,0(s1)
    80003e08:	ff3716e3          	bne	a4,s3,80003df4 <iget+0x38>
    80003e0c:	40d8                	lw	a4,4(s1)
    80003e0e:	ff4713e3          	bne	a4,s4,80003df4 <iget+0x38>
      ip->ref++;
    80003e12:	2785                	addiw	a5,a5,1
    80003e14:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003e16:	00021517          	auipc	a0,0x21
    80003e1a:	65250513          	addi	a0,a0,1618 # 80025468 <itable>
    80003e1e:	ffffd097          	auipc	ra,0xffffd
    80003e22:	ece080e7          	jalr	-306(ra) # 80000cec <release>
      return ip;
    80003e26:	8926                	mv	s2,s1
    80003e28:	a03d                	j	80003e56 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003e2a:	f7f9                	bnez	a5,80003df8 <iget+0x3c>
      empty = ip;
    80003e2c:	8926                	mv	s2,s1
    80003e2e:	b7e9                	j	80003df8 <iget+0x3c>
  if(empty == 0)
    80003e30:	02090c63          	beqz	s2,80003e68 <iget+0xac>
  ip->dev = dev;
    80003e34:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003e38:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003e3c:	4785                	li	a5,1
    80003e3e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003e42:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003e46:	00021517          	auipc	a0,0x21
    80003e4a:	62250513          	addi	a0,a0,1570 # 80025468 <itable>
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	e9e080e7          	jalr	-354(ra) # 80000cec <release>
}
    80003e56:	854a                	mv	a0,s2
    80003e58:	70a2                	ld	ra,40(sp)
    80003e5a:	7402                	ld	s0,32(sp)
    80003e5c:	64e2                	ld	s1,24(sp)
    80003e5e:	6942                	ld	s2,16(sp)
    80003e60:	69a2                	ld	s3,8(sp)
    80003e62:	6a02                	ld	s4,0(sp)
    80003e64:	6145                	addi	sp,sp,48
    80003e66:	8082                	ret
    panic("iget: no inodes");
    80003e68:	00004517          	auipc	a0,0x4
    80003e6c:	63850513          	addi	a0,a0,1592 # 800084a0 <etext+0x4a0>
    80003e70:	ffffc097          	auipc	ra,0xffffc
    80003e74:	6f0080e7          	jalr	1776(ra) # 80000560 <panic>

0000000080003e78 <fsinit>:
fsinit(int dev) {
    80003e78:	7179                	addi	sp,sp,-48
    80003e7a:	f406                	sd	ra,40(sp)
    80003e7c:	f022                	sd	s0,32(sp)
    80003e7e:	ec26                	sd	s1,24(sp)
    80003e80:	e84a                	sd	s2,16(sp)
    80003e82:	e44e                	sd	s3,8(sp)
    80003e84:	1800                	addi	s0,sp,48
    80003e86:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003e88:	4585                	li	a1,1
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	a3e080e7          	jalr	-1474(ra) # 800038c8 <bread>
    80003e92:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003e94:	00021997          	auipc	s3,0x21
    80003e98:	5b498993          	addi	s3,s3,1460 # 80025448 <sb>
    80003e9c:	02000613          	li	a2,32
    80003ea0:	05850593          	addi	a1,a0,88
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	ffffd097          	auipc	ra,0xffffd
    80003eaa:	eea080e7          	jalr	-278(ra) # 80000d90 <memmove>
  brelse(bp);
    80003eae:	8526                	mv	a0,s1
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	b48080e7          	jalr	-1208(ra) # 800039f8 <brelse>
  if(sb.magic != FSMAGIC)
    80003eb8:	0009a703          	lw	a4,0(s3)
    80003ebc:	102037b7          	lui	a5,0x10203
    80003ec0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ec4:	02f71263          	bne	a4,a5,80003ee8 <fsinit+0x70>
  initlog(dev, &sb);
    80003ec8:	00021597          	auipc	a1,0x21
    80003ecc:	58058593          	addi	a1,a1,1408 # 80025448 <sb>
    80003ed0:	854a                	mv	a0,s2
    80003ed2:	00001097          	auipc	ra,0x1
    80003ed6:	b60080e7          	jalr	-1184(ra) # 80004a32 <initlog>
}
    80003eda:	70a2                	ld	ra,40(sp)
    80003edc:	7402                	ld	s0,32(sp)
    80003ede:	64e2                	ld	s1,24(sp)
    80003ee0:	6942                	ld	s2,16(sp)
    80003ee2:	69a2                	ld	s3,8(sp)
    80003ee4:	6145                	addi	sp,sp,48
    80003ee6:	8082                	ret
    panic("invalid file system");
    80003ee8:	00004517          	auipc	a0,0x4
    80003eec:	5c850513          	addi	a0,a0,1480 # 800084b0 <etext+0x4b0>
    80003ef0:	ffffc097          	auipc	ra,0xffffc
    80003ef4:	670080e7          	jalr	1648(ra) # 80000560 <panic>

0000000080003ef8 <iinit>:
{
    80003ef8:	7179                	addi	sp,sp,-48
    80003efa:	f406                	sd	ra,40(sp)
    80003efc:	f022                	sd	s0,32(sp)
    80003efe:	ec26                	sd	s1,24(sp)
    80003f00:	e84a                	sd	s2,16(sp)
    80003f02:	e44e                	sd	s3,8(sp)
    80003f04:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003f06:	00004597          	auipc	a1,0x4
    80003f0a:	5c258593          	addi	a1,a1,1474 # 800084c8 <etext+0x4c8>
    80003f0e:	00021517          	auipc	a0,0x21
    80003f12:	55a50513          	addi	a0,a0,1370 # 80025468 <itable>
    80003f16:	ffffd097          	auipc	ra,0xffffd
    80003f1a:	c92080e7          	jalr	-878(ra) # 80000ba8 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003f1e:	00021497          	auipc	s1,0x21
    80003f22:	57248493          	addi	s1,s1,1394 # 80025490 <itable+0x28>
    80003f26:	00023997          	auipc	s3,0x23
    80003f2a:	ffa98993          	addi	s3,s3,-6 # 80026f20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003f2e:	00004917          	auipc	s2,0x4
    80003f32:	5a290913          	addi	s2,s2,1442 # 800084d0 <etext+0x4d0>
    80003f36:	85ca                	mv	a1,s2
    80003f38:	8526                	mv	a0,s1
    80003f3a:	00001097          	auipc	ra,0x1
    80003f3e:	e4c080e7          	jalr	-436(ra) # 80004d86 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003f42:	08848493          	addi	s1,s1,136
    80003f46:	ff3498e3          	bne	s1,s3,80003f36 <iinit+0x3e>
}
    80003f4a:	70a2                	ld	ra,40(sp)
    80003f4c:	7402                	ld	s0,32(sp)
    80003f4e:	64e2                	ld	s1,24(sp)
    80003f50:	6942                	ld	s2,16(sp)
    80003f52:	69a2                	ld	s3,8(sp)
    80003f54:	6145                	addi	sp,sp,48
    80003f56:	8082                	ret

0000000080003f58 <ialloc>:
{
    80003f58:	7139                	addi	sp,sp,-64
    80003f5a:	fc06                	sd	ra,56(sp)
    80003f5c:	f822                	sd	s0,48(sp)
    80003f5e:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003f60:	00021717          	auipc	a4,0x21
    80003f64:	4f472703          	lw	a4,1268(a4) # 80025454 <sb+0xc>
    80003f68:	4785                	li	a5,1
    80003f6a:	06e7f463          	bgeu	a5,a4,80003fd2 <ialloc+0x7a>
    80003f6e:	f426                	sd	s1,40(sp)
    80003f70:	f04a                	sd	s2,32(sp)
    80003f72:	ec4e                	sd	s3,24(sp)
    80003f74:	e852                	sd	s4,16(sp)
    80003f76:	e456                	sd	s5,8(sp)
    80003f78:	e05a                	sd	s6,0(sp)
    80003f7a:	8aaa                	mv	s5,a0
    80003f7c:	8b2e                	mv	s6,a1
    80003f7e:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003f80:	00021a17          	auipc	s4,0x21
    80003f84:	4c8a0a13          	addi	s4,s4,1224 # 80025448 <sb>
    80003f88:	00495593          	srli	a1,s2,0x4
    80003f8c:	018a2783          	lw	a5,24(s4)
    80003f90:	9dbd                	addw	a1,a1,a5
    80003f92:	8556                	mv	a0,s5
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	934080e7          	jalr	-1740(ra) # 800038c8 <bread>
    80003f9c:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003f9e:	05850993          	addi	s3,a0,88
    80003fa2:	00f97793          	andi	a5,s2,15
    80003fa6:	079a                	slli	a5,a5,0x6
    80003fa8:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003faa:	00099783          	lh	a5,0(s3)
    80003fae:	cf9d                	beqz	a5,80003fec <ialloc+0x94>
    brelse(bp);
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	a48080e7          	jalr	-1464(ra) # 800039f8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003fb8:	0905                	addi	s2,s2,1
    80003fba:	00ca2703          	lw	a4,12(s4)
    80003fbe:	0009079b          	sext.w	a5,s2
    80003fc2:	fce7e3e3          	bltu	a5,a4,80003f88 <ialloc+0x30>
    80003fc6:	74a2                	ld	s1,40(sp)
    80003fc8:	7902                	ld	s2,32(sp)
    80003fca:	69e2                	ld	s3,24(sp)
    80003fcc:	6a42                	ld	s4,16(sp)
    80003fce:	6aa2                	ld	s5,8(sp)
    80003fd0:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    80003fd2:	00004517          	auipc	a0,0x4
    80003fd6:	50650513          	addi	a0,a0,1286 # 800084d8 <etext+0x4d8>
    80003fda:	ffffc097          	auipc	ra,0xffffc
    80003fde:	5d0080e7          	jalr	1488(ra) # 800005aa <printf>
  return 0;
    80003fe2:	4501                	li	a0,0
}
    80003fe4:	70e2                	ld	ra,56(sp)
    80003fe6:	7442                	ld	s0,48(sp)
    80003fe8:	6121                	addi	sp,sp,64
    80003fea:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003fec:	04000613          	li	a2,64
    80003ff0:	4581                	li	a1,0
    80003ff2:	854e                	mv	a0,s3
    80003ff4:	ffffd097          	auipc	ra,0xffffd
    80003ff8:	d40080e7          	jalr	-704(ra) # 80000d34 <memset>
      dip->type = type;
    80003ffc:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004000:	8526                	mv	a0,s1
    80004002:	00001097          	auipc	ra,0x1
    80004006:	ca0080e7          	jalr	-864(ra) # 80004ca2 <log_write>
      brelse(bp);
    8000400a:	8526                	mv	a0,s1
    8000400c:	00000097          	auipc	ra,0x0
    80004010:	9ec080e7          	jalr	-1556(ra) # 800039f8 <brelse>
      return iget(dev, inum);
    80004014:	0009059b          	sext.w	a1,s2
    80004018:	8556                	mv	a0,s5
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	da2080e7          	jalr	-606(ra) # 80003dbc <iget>
    80004022:	74a2                	ld	s1,40(sp)
    80004024:	7902                	ld	s2,32(sp)
    80004026:	69e2                	ld	s3,24(sp)
    80004028:	6a42                	ld	s4,16(sp)
    8000402a:	6aa2                	ld	s5,8(sp)
    8000402c:	6b02                	ld	s6,0(sp)
    8000402e:	bf5d                	j	80003fe4 <ialloc+0x8c>

0000000080004030 <iupdate>:
{
    80004030:	1101                	addi	sp,sp,-32
    80004032:	ec06                	sd	ra,24(sp)
    80004034:	e822                	sd	s0,16(sp)
    80004036:	e426                	sd	s1,8(sp)
    80004038:	e04a                	sd	s2,0(sp)
    8000403a:	1000                	addi	s0,sp,32
    8000403c:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000403e:	415c                	lw	a5,4(a0)
    80004040:	0047d79b          	srliw	a5,a5,0x4
    80004044:	00021597          	auipc	a1,0x21
    80004048:	41c5a583          	lw	a1,1052(a1) # 80025460 <sb+0x18>
    8000404c:	9dbd                	addw	a1,a1,a5
    8000404e:	4108                	lw	a0,0(a0)
    80004050:	00000097          	auipc	ra,0x0
    80004054:	878080e7          	jalr	-1928(ra) # 800038c8 <bread>
    80004058:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000405a:	05850793          	addi	a5,a0,88
    8000405e:	40d8                	lw	a4,4(s1)
    80004060:	8b3d                	andi	a4,a4,15
    80004062:	071a                	slli	a4,a4,0x6
    80004064:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80004066:	04449703          	lh	a4,68(s1)
    8000406a:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    8000406e:	04649703          	lh	a4,70(s1)
    80004072:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80004076:	04849703          	lh	a4,72(s1)
    8000407a:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    8000407e:	04a49703          	lh	a4,74(s1)
    80004082:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80004086:	44f8                	lw	a4,76(s1)
    80004088:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000408a:	03400613          	li	a2,52
    8000408e:	05048593          	addi	a1,s1,80
    80004092:	00c78513          	addi	a0,a5,12
    80004096:	ffffd097          	auipc	ra,0xffffd
    8000409a:	cfa080e7          	jalr	-774(ra) # 80000d90 <memmove>
  log_write(bp);
    8000409e:	854a                	mv	a0,s2
    800040a0:	00001097          	auipc	ra,0x1
    800040a4:	c02080e7          	jalr	-1022(ra) # 80004ca2 <log_write>
  brelse(bp);
    800040a8:	854a                	mv	a0,s2
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	94e080e7          	jalr	-1714(ra) # 800039f8 <brelse>
}
    800040b2:	60e2                	ld	ra,24(sp)
    800040b4:	6442                	ld	s0,16(sp)
    800040b6:	64a2                	ld	s1,8(sp)
    800040b8:	6902                	ld	s2,0(sp)
    800040ba:	6105                	addi	sp,sp,32
    800040bc:	8082                	ret

00000000800040be <idup>:
{
    800040be:	1101                	addi	sp,sp,-32
    800040c0:	ec06                	sd	ra,24(sp)
    800040c2:	e822                	sd	s0,16(sp)
    800040c4:	e426                	sd	s1,8(sp)
    800040c6:	1000                	addi	s0,sp,32
    800040c8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800040ca:	00021517          	auipc	a0,0x21
    800040ce:	39e50513          	addi	a0,a0,926 # 80025468 <itable>
    800040d2:	ffffd097          	auipc	ra,0xffffd
    800040d6:	b66080e7          	jalr	-1178(ra) # 80000c38 <acquire>
  ip->ref++;
    800040da:	449c                	lw	a5,8(s1)
    800040dc:	2785                	addiw	a5,a5,1
    800040de:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800040e0:	00021517          	auipc	a0,0x21
    800040e4:	38850513          	addi	a0,a0,904 # 80025468 <itable>
    800040e8:	ffffd097          	auipc	ra,0xffffd
    800040ec:	c04080e7          	jalr	-1020(ra) # 80000cec <release>
}
    800040f0:	8526                	mv	a0,s1
    800040f2:	60e2                	ld	ra,24(sp)
    800040f4:	6442                	ld	s0,16(sp)
    800040f6:	64a2                	ld	s1,8(sp)
    800040f8:	6105                	addi	sp,sp,32
    800040fa:	8082                	ret

00000000800040fc <ilock>:
{
    800040fc:	1101                	addi	sp,sp,-32
    800040fe:	ec06                	sd	ra,24(sp)
    80004100:	e822                	sd	s0,16(sp)
    80004102:	e426                	sd	s1,8(sp)
    80004104:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004106:	c10d                	beqz	a0,80004128 <ilock+0x2c>
    80004108:	84aa                	mv	s1,a0
    8000410a:	451c                	lw	a5,8(a0)
    8000410c:	00f05e63          	blez	a5,80004128 <ilock+0x2c>
  acquiresleep(&ip->lock);
    80004110:	0541                	addi	a0,a0,16
    80004112:	00001097          	auipc	ra,0x1
    80004116:	cae080e7          	jalr	-850(ra) # 80004dc0 <acquiresleep>
  if(ip->valid == 0){
    8000411a:	40bc                	lw	a5,64(s1)
    8000411c:	cf99                	beqz	a5,8000413a <ilock+0x3e>
}
    8000411e:	60e2                	ld	ra,24(sp)
    80004120:	6442                	ld	s0,16(sp)
    80004122:	64a2                	ld	s1,8(sp)
    80004124:	6105                	addi	sp,sp,32
    80004126:	8082                	ret
    80004128:	e04a                	sd	s2,0(sp)
    panic("ilock");
    8000412a:	00004517          	auipc	a0,0x4
    8000412e:	3c650513          	addi	a0,a0,966 # 800084f0 <etext+0x4f0>
    80004132:	ffffc097          	auipc	ra,0xffffc
    80004136:	42e080e7          	jalr	1070(ra) # 80000560 <panic>
    8000413a:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000413c:	40dc                	lw	a5,4(s1)
    8000413e:	0047d79b          	srliw	a5,a5,0x4
    80004142:	00021597          	auipc	a1,0x21
    80004146:	31e5a583          	lw	a1,798(a1) # 80025460 <sb+0x18>
    8000414a:	9dbd                	addw	a1,a1,a5
    8000414c:	4088                	lw	a0,0(s1)
    8000414e:	fffff097          	auipc	ra,0xfffff
    80004152:	77a080e7          	jalr	1914(ra) # 800038c8 <bread>
    80004156:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004158:	05850593          	addi	a1,a0,88
    8000415c:	40dc                	lw	a5,4(s1)
    8000415e:	8bbd                	andi	a5,a5,15
    80004160:	079a                	slli	a5,a5,0x6
    80004162:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004164:	00059783          	lh	a5,0(a1)
    80004168:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000416c:	00259783          	lh	a5,2(a1)
    80004170:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004174:	00459783          	lh	a5,4(a1)
    80004178:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000417c:	00659783          	lh	a5,6(a1)
    80004180:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004184:	459c                	lw	a5,8(a1)
    80004186:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80004188:	03400613          	li	a2,52
    8000418c:	05b1                	addi	a1,a1,12
    8000418e:	05048513          	addi	a0,s1,80
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	bfe080e7          	jalr	-1026(ra) # 80000d90 <memmove>
    brelse(bp);
    8000419a:	854a                	mv	a0,s2
    8000419c:	00000097          	auipc	ra,0x0
    800041a0:	85c080e7          	jalr	-1956(ra) # 800039f8 <brelse>
    ip->valid = 1;
    800041a4:	4785                	li	a5,1
    800041a6:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800041a8:	04449783          	lh	a5,68(s1)
    800041ac:	c399                	beqz	a5,800041b2 <ilock+0xb6>
    800041ae:	6902                	ld	s2,0(sp)
    800041b0:	b7bd                	j	8000411e <ilock+0x22>
      panic("ilock: no type");
    800041b2:	00004517          	auipc	a0,0x4
    800041b6:	34650513          	addi	a0,a0,838 # 800084f8 <etext+0x4f8>
    800041ba:	ffffc097          	auipc	ra,0xffffc
    800041be:	3a6080e7          	jalr	934(ra) # 80000560 <panic>

00000000800041c2 <iunlock>:
{
    800041c2:	1101                	addi	sp,sp,-32
    800041c4:	ec06                	sd	ra,24(sp)
    800041c6:	e822                	sd	s0,16(sp)
    800041c8:	e426                	sd	s1,8(sp)
    800041ca:	e04a                	sd	s2,0(sp)
    800041cc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800041ce:	c905                	beqz	a0,800041fe <iunlock+0x3c>
    800041d0:	84aa                	mv	s1,a0
    800041d2:	01050913          	addi	s2,a0,16
    800041d6:	854a                	mv	a0,s2
    800041d8:	00001097          	auipc	ra,0x1
    800041dc:	c82080e7          	jalr	-894(ra) # 80004e5a <holdingsleep>
    800041e0:	cd19                	beqz	a0,800041fe <iunlock+0x3c>
    800041e2:	449c                	lw	a5,8(s1)
    800041e4:	00f05d63          	blez	a5,800041fe <iunlock+0x3c>
  releasesleep(&ip->lock);
    800041e8:	854a                	mv	a0,s2
    800041ea:	00001097          	auipc	ra,0x1
    800041ee:	c2c080e7          	jalr	-980(ra) # 80004e16 <releasesleep>
}
    800041f2:	60e2                	ld	ra,24(sp)
    800041f4:	6442                	ld	s0,16(sp)
    800041f6:	64a2                	ld	s1,8(sp)
    800041f8:	6902                	ld	s2,0(sp)
    800041fa:	6105                	addi	sp,sp,32
    800041fc:	8082                	ret
    panic("iunlock");
    800041fe:	00004517          	auipc	a0,0x4
    80004202:	30a50513          	addi	a0,a0,778 # 80008508 <etext+0x508>
    80004206:	ffffc097          	auipc	ra,0xffffc
    8000420a:	35a080e7          	jalr	858(ra) # 80000560 <panic>

000000008000420e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000420e:	7179                	addi	sp,sp,-48
    80004210:	f406                	sd	ra,40(sp)
    80004212:	f022                	sd	s0,32(sp)
    80004214:	ec26                	sd	s1,24(sp)
    80004216:	e84a                	sd	s2,16(sp)
    80004218:	e44e                	sd	s3,8(sp)
    8000421a:	1800                	addi	s0,sp,48
    8000421c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000421e:	05050493          	addi	s1,a0,80
    80004222:	08050913          	addi	s2,a0,128
    80004226:	a021                	j	8000422e <itrunc+0x20>
    80004228:	0491                	addi	s1,s1,4
    8000422a:	01248d63          	beq	s1,s2,80004244 <itrunc+0x36>
    if(ip->addrs[i]){
    8000422e:	408c                	lw	a1,0(s1)
    80004230:	dde5                	beqz	a1,80004228 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    80004232:	0009a503          	lw	a0,0(s3)
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	8d6080e7          	jalr	-1834(ra) # 80003b0c <bfree>
      ip->addrs[i] = 0;
    8000423e:	0004a023          	sw	zero,0(s1)
    80004242:	b7dd                	j	80004228 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004244:	0809a583          	lw	a1,128(s3)
    80004248:	ed99                	bnez	a1,80004266 <itrunc+0x58>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000424a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000424e:	854e                	mv	a0,s3
    80004250:	00000097          	auipc	ra,0x0
    80004254:	de0080e7          	jalr	-544(ra) # 80004030 <iupdate>
}
    80004258:	70a2                	ld	ra,40(sp)
    8000425a:	7402                	ld	s0,32(sp)
    8000425c:	64e2                	ld	s1,24(sp)
    8000425e:	6942                	ld	s2,16(sp)
    80004260:	69a2                	ld	s3,8(sp)
    80004262:	6145                	addi	sp,sp,48
    80004264:	8082                	ret
    80004266:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004268:	0009a503          	lw	a0,0(s3)
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	65c080e7          	jalr	1628(ra) # 800038c8 <bread>
    80004274:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004276:	05850493          	addi	s1,a0,88
    8000427a:	45850913          	addi	s2,a0,1112
    8000427e:	a021                	j	80004286 <itrunc+0x78>
    80004280:	0491                	addi	s1,s1,4
    80004282:	01248b63          	beq	s1,s2,80004298 <itrunc+0x8a>
      if(a[j])
    80004286:	408c                	lw	a1,0(s1)
    80004288:	dde5                	beqz	a1,80004280 <itrunc+0x72>
        bfree(ip->dev, a[j]);
    8000428a:	0009a503          	lw	a0,0(s3)
    8000428e:	00000097          	auipc	ra,0x0
    80004292:	87e080e7          	jalr	-1922(ra) # 80003b0c <bfree>
    80004296:	b7ed                	j	80004280 <itrunc+0x72>
    brelse(bp);
    80004298:	8552                	mv	a0,s4
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	75e080e7          	jalr	1886(ra) # 800039f8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800042a2:	0809a583          	lw	a1,128(s3)
    800042a6:	0009a503          	lw	a0,0(s3)
    800042aa:	00000097          	auipc	ra,0x0
    800042ae:	862080e7          	jalr	-1950(ra) # 80003b0c <bfree>
    ip->addrs[NDIRECT] = 0;
    800042b2:	0809a023          	sw	zero,128(s3)
    800042b6:	6a02                	ld	s4,0(sp)
    800042b8:	bf49                	j	8000424a <itrunc+0x3c>

00000000800042ba <iput>:
{
    800042ba:	1101                	addi	sp,sp,-32
    800042bc:	ec06                	sd	ra,24(sp)
    800042be:	e822                	sd	s0,16(sp)
    800042c0:	e426                	sd	s1,8(sp)
    800042c2:	1000                	addi	s0,sp,32
    800042c4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042c6:	00021517          	auipc	a0,0x21
    800042ca:	1a250513          	addi	a0,a0,418 # 80025468 <itable>
    800042ce:	ffffd097          	auipc	ra,0xffffd
    800042d2:	96a080e7          	jalr	-1686(ra) # 80000c38 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042d6:	4498                	lw	a4,8(s1)
    800042d8:	4785                	li	a5,1
    800042da:	02f70263          	beq	a4,a5,800042fe <iput+0x44>
  ip->ref--;
    800042de:	449c                	lw	a5,8(s1)
    800042e0:	37fd                	addiw	a5,a5,-1
    800042e2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800042e4:	00021517          	auipc	a0,0x21
    800042e8:	18450513          	addi	a0,a0,388 # 80025468 <itable>
    800042ec:	ffffd097          	auipc	ra,0xffffd
    800042f0:	a00080e7          	jalr	-1536(ra) # 80000cec <release>
}
    800042f4:	60e2                	ld	ra,24(sp)
    800042f6:	6442                	ld	s0,16(sp)
    800042f8:	64a2                	ld	s1,8(sp)
    800042fa:	6105                	addi	sp,sp,32
    800042fc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800042fe:	40bc                	lw	a5,64(s1)
    80004300:	dff9                	beqz	a5,800042de <iput+0x24>
    80004302:	04a49783          	lh	a5,74(s1)
    80004306:	ffe1                	bnez	a5,800042de <iput+0x24>
    80004308:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    8000430a:	01048913          	addi	s2,s1,16
    8000430e:	854a                	mv	a0,s2
    80004310:	00001097          	auipc	ra,0x1
    80004314:	ab0080e7          	jalr	-1360(ra) # 80004dc0 <acquiresleep>
    release(&itable.lock);
    80004318:	00021517          	auipc	a0,0x21
    8000431c:	15050513          	addi	a0,a0,336 # 80025468 <itable>
    80004320:	ffffd097          	auipc	ra,0xffffd
    80004324:	9cc080e7          	jalr	-1588(ra) # 80000cec <release>
    itrunc(ip);
    80004328:	8526                	mv	a0,s1
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	ee4080e7          	jalr	-284(ra) # 8000420e <itrunc>
    ip->type = 0;
    80004332:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004336:	8526                	mv	a0,s1
    80004338:	00000097          	auipc	ra,0x0
    8000433c:	cf8080e7          	jalr	-776(ra) # 80004030 <iupdate>
    ip->valid = 0;
    80004340:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004344:	854a                	mv	a0,s2
    80004346:	00001097          	auipc	ra,0x1
    8000434a:	ad0080e7          	jalr	-1328(ra) # 80004e16 <releasesleep>
    acquire(&itable.lock);
    8000434e:	00021517          	auipc	a0,0x21
    80004352:	11a50513          	addi	a0,a0,282 # 80025468 <itable>
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	8e2080e7          	jalr	-1822(ra) # 80000c38 <acquire>
    8000435e:	6902                	ld	s2,0(sp)
    80004360:	bfbd                	j	800042de <iput+0x24>

0000000080004362 <iunlockput>:
{
    80004362:	1101                	addi	sp,sp,-32
    80004364:	ec06                	sd	ra,24(sp)
    80004366:	e822                	sd	s0,16(sp)
    80004368:	e426                	sd	s1,8(sp)
    8000436a:	1000                	addi	s0,sp,32
    8000436c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000436e:	00000097          	auipc	ra,0x0
    80004372:	e54080e7          	jalr	-428(ra) # 800041c2 <iunlock>
  iput(ip);
    80004376:	8526                	mv	a0,s1
    80004378:	00000097          	auipc	ra,0x0
    8000437c:	f42080e7          	jalr	-190(ra) # 800042ba <iput>
}
    80004380:	60e2                	ld	ra,24(sp)
    80004382:	6442                	ld	s0,16(sp)
    80004384:	64a2                	ld	s1,8(sp)
    80004386:	6105                	addi	sp,sp,32
    80004388:	8082                	ret

000000008000438a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    8000438a:	1141                	addi	sp,sp,-16
    8000438c:	e422                	sd	s0,8(sp)
    8000438e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004390:	411c                	lw	a5,0(a0)
    80004392:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004394:	415c                	lw	a5,4(a0)
    80004396:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004398:	04451783          	lh	a5,68(a0)
    8000439c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800043a0:	04a51783          	lh	a5,74(a0)
    800043a4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800043a8:	04c56783          	lwu	a5,76(a0)
    800043ac:	e99c                	sd	a5,16(a1)
}
    800043ae:	6422                	ld	s0,8(sp)
    800043b0:	0141                	addi	sp,sp,16
    800043b2:	8082                	ret

00000000800043b4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800043b4:	457c                	lw	a5,76(a0)
    800043b6:	10d7e563          	bltu	a5,a3,800044c0 <readi+0x10c>
{
    800043ba:	7159                	addi	sp,sp,-112
    800043bc:	f486                	sd	ra,104(sp)
    800043be:	f0a2                	sd	s0,96(sp)
    800043c0:	eca6                	sd	s1,88(sp)
    800043c2:	e0d2                	sd	s4,64(sp)
    800043c4:	fc56                	sd	s5,56(sp)
    800043c6:	f85a                	sd	s6,48(sp)
    800043c8:	f45e                	sd	s7,40(sp)
    800043ca:	1880                	addi	s0,sp,112
    800043cc:	8b2a                	mv	s6,a0
    800043ce:	8bae                	mv	s7,a1
    800043d0:	8a32                	mv	s4,a2
    800043d2:	84b6                	mv	s1,a3
    800043d4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800043d6:	9f35                	addw	a4,a4,a3
    return 0;
    800043d8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800043da:	0cd76a63          	bltu	a4,a3,800044ae <readi+0xfa>
    800043de:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    800043e0:	00e7f463          	bgeu	a5,a4,800043e8 <readi+0x34>
    n = ip->size - off;
    800043e4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800043e8:	0a0a8963          	beqz	s5,8000449a <readi+0xe6>
    800043ec:	e8ca                	sd	s2,80(sp)
    800043ee:	f062                	sd	s8,32(sp)
    800043f0:	ec66                	sd	s9,24(sp)
    800043f2:	e86a                	sd	s10,16(sp)
    800043f4:	e46e                	sd	s11,8(sp)
    800043f6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800043f8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800043fc:	5c7d                	li	s8,-1
    800043fe:	a82d                	j	80004438 <readi+0x84>
    80004400:	020d1d93          	slli	s11,s10,0x20
    80004404:	020ddd93          	srli	s11,s11,0x20
    80004408:	05890613          	addi	a2,s2,88
    8000440c:	86ee                	mv	a3,s11
    8000440e:	963a                	add	a2,a2,a4
    80004410:	85d2                	mv	a1,s4
    80004412:	855e                	mv	a0,s7
    80004414:	ffffe097          	auipc	ra,0xffffe
    80004418:	59e080e7          	jalr	1438(ra) # 800029b2 <either_copyout>
    8000441c:	05850d63          	beq	a0,s8,80004476 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004420:	854a                	mv	a0,s2
    80004422:	fffff097          	auipc	ra,0xfffff
    80004426:	5d6080e7          	jalr	1494(ra) # 800039f8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000442a:	013d09bb          	addw	s3,s10,s3
    8000442e:	009d04bb          	addw	s1,s10,s1
    80004432:	9a6e                	add	s4,s4,s11
    80004434:	0559fd63          	bgeu	s3,s5,8000448e <readi+0xda>
    uint addr = bmap(ip, off/BSIZE);
    80004438:	00a4d59b          	srliw	a1,s1,0xa
    8000443c:	855a                	mv	a0,s6
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	88e080e7          	jalr	-1906(ra) # 80003ccc <bmap>
    80004446:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000444a:	c9b1                	beqz	a1,8000449e <readi+0xea>
    bp = bread(ip->dev, addr);
    8000444c:	000b2503          	lw	a0,0(s6)
    80004450:	fffff097          	auipc	ra,0xfffff
    80004454:	478080e7          	jalr	1144(ra) # 800038c8 <bread>
    80004458:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000445a:	3ff4f713          	andi	a4,s1,1023
    8000445e:	40ec87bb          	subw	a5,s9,a4
    80004462:	413a86bb          	subw	a3,s5,s3
    80004466:	8d3e                	mv	s10,a5
    80004468:	2781                	sext.w	a5,a5
    8000446a:	0006861b          	sext.w	a2,a3
    8000446e:	f8f679e3          	bgeu	a2,a5,80004400 <readi+0x4c>
    80004472:	8d36                	mv	s10,a3
    80004474:	b771                	j	80004400 <readi+0x4c>
      brelse(bp);
    80004476:	854a                	mv	a0,s2
    80004478:	fffff097          	auipc	ra,0xfffff
    8000447c:	580080e7          	jalr	1408(ra) # 800039f8 <brelse>
      tot = -1;
    80004480:	59fd                	li	s3,-1
      break;
    80004482:	6946                	ld	s2,80(sp)
    80004484:	7c02                	ld	s8,32(sp)
    80004486:	6ce2                	ld	s9,24(sp)
    80004488:	6d42                	ld	s10,16(sp)
    8000448a:	6da2                	ld	s11,8(sp)
    8000448c:	a831                	j	800044a8 <readi+0xf4>
    8000448e:	6946                	ld	s2,80(sp)
    80004490:	7c02                	ld	s8,32(sp)
    80004492:	6ce2                	ld	s9,24(sp)
    80004494:	6d42                	ld	s10,16(sp)
    80004496:	6da2                	ld	s11,8(sp)
    80004498:	a801                	j	800044a8 <readi+0xf4>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000449a:	89d6                	mv	s3,s5
    8000449c:	a031                	j	800044a8 <readi+0xf4>
    8000449e:	6946                	ld	s2,80(sp)
    800044a0:	7c02                	ld	s8,32(sp)
    800044a2:	6ce2                	ld	s9,24(sp)
    800044a4:	6d42                	ld	s10,16(sp)
    800044a6:	6da2                	ld	s11,8(sp)
  }
  return tot;
    800044a8:	0009851b          	sext.w	a0,s3
    800044ac:	69a6                	ld	s3,72(sp)
}
    800044ae:	70a6                	ld	ra,104(sp)
    800044b0:	7406                	ld	s0,96(sp)
    800044b2:	64e6                	ld	s1,88(sp)
    800044b4:	6a06                	ld	s4,64(sp)
    800044b6:	7ae2                	ld	s5,56(sp)
    800044b8:	7b42                	ld	s6,48(sp)
    800044ba:	7ba2                	ld	s7,40(sp)
    800044bc:	6165                	addi	sp,sp,112
    800044be:	8082                	ret
    return 0;
    800044c0:	4501                	li	a0,0
}
    800044c2:	8082                	ret

00000000800044c4 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800044c4:	457c                	lw	a5,76(a0)
    800044c6:	10d7ee63          	bltu	a5,a3,800045e2 <writei+0x11e>
{
    800044ca:	7159                	addi	sp,sp,-112
    800044cc:	f486                	sd	ra,104(sp)
    800044ce:	f0a2                	sd	s0,96(sp)
    800044d0:	e8ca                	sd	s2,80(sp)
    800044d2:	e0d2                	sd	s4,64(sp)
    800044d4:	fc56                	sd	s5,56(sp)
    800044d6:	f85a                	sd	s6,48(sp)
    800044d8:	f45e                	sd	s7,40(sp)
    800044da:	1880                	addi	s0,sp,112
    800044dc:	8aaa                	mv	s5,a0
    800044de:	8bae                	mv	s7,a1
    800044e0:	8a32                	mv	s4,a2
    800044e2:	8936                	mv	s2,a3
    800044e4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800044e6:	00e687bb          	addw	a5,a3,a4
    800044ea:	0ed7ee63          	bltu	a5,a3,800045e6 <writei+0x122>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800044ee:	00043737          	lui	a4,0x43
    800044f2:	0ef76c63          	bltu	a4,a5,800045ea <writei+0x126>
    800044f6:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800044f8:	0c0b0d63          	beqz	s6,800045d2 <writei+0x10e>
    800044fc:	eca6                	sd	s1,88(sp)
    800044fe:	f062                	sd	s8,32(sp)
    80004500:	ec66                	sd	s9,24(sp)
    80004502:	e86a                	sd	s10,16(sp)
    80004504:	e46e                	sd	s11,8(sp)
    80004506:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004508:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000450c:	5c7d                	li	s8,-1
    8000450e:	a091                	j	80004552 <writei+0x8e>
    80004510:	020d1d93          	slli	s11,s10,0x20
    80004514:	020ddd93          	srli	s11,s11,0x20
    80004518:	05848513          	addi	a0,s1,88
    8000451c:	86ee                	mv	a3,s11
    8000451e:	8652                	mv	a2,s4
    80004520:	85de                	mv	a1,s7
    80004522:	953a                	add	a0,a0,a4
    80004524:	ffffe097          	auipc	ra,0xffffe
    80004528:	4e4080e7          	jalr	1252(ra) # 80002a08 <either_copyin>
    8000452c:	07850263          	beq	a0,s8,80004590 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004530:	8526                	mv	a0,s1
    80004532:	00000097          	auipc	ra,0x0
    80004536:	770080e7          	jalr	1904(ra) # 80004ca2 <log_write>
    brelse(bp);
    8000453a:	8526                	mv	a0,s1
    8000453c:	fffff097          	auipc	ra,0xfffff
    80004540:	4bc080e7          	jalr	1212(ra) # 800039f8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004544:	013d09bb          	addw	s3,s10,s3
    80004548:	012d093b          	addw	s2,s10,s2
    8000454c:	9a6e                	add	s4,s4,s11
    8000454e:	0569f663          	bgeu	s3,s6,8000459a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004552:	00a9559b          	srliw	a1,s2,0xa
    80004556:	8556                	mv	a0,s5
    80004558:	fffff097          	auipc	ra,0xfffff
    8000455c:	774080e7          	jalr	1908(ra) # 80003ccc <bmap>
    80004560:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004564:	c99d                	beqz	a1,8000459a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004566:	000aa503          	lw	a0,0(s5)
    8000456a:	fffff097          	auipc	ra,0xfffff
    8000456e:	35e080e7          	jalr	862(ra) # 800038c8 <bread>
    80004572:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004574:	3ff97713          	andi	a4,s2,1023
    80004578:	40ec87bb          	subw	a5,s9,a4
    8000457c:	413b06bb          	subw	a3,s6,s3
    80004580:	8d3e                	mv	s10,a5
    80004582:	2781                	sext.w	a5,a5
    80004584:	0006861b          	sext.w	a2,a3
    80004588:	f8f674e3          	bgeu	a2,a5,80004510 <writei+0x4c>
    8000458c:	8d36                	mv	s10,a3
    8000458e:	b749                	j	80004510 <writei+0x4c>
      brelse(bp);
    80004590:	8526                	mv	a0,s1
    80004592:	fffff097          	auipc	ra,0xfffff
    80004596:	466080e7          	jalr	1126(ra) # 800039f8 <brelse>
  }

  if(off > ip->size)
    8000459a:	04caa783          	lw	a5,76(s5)
    8000459e:	0327fc63          	bgeu	a5,s2,800045d6 <writei+0x112>
    ip->size = off;
    800045a2:	052aa623          	sw	s2,76(s5)
    800045a6:	64e6                	ld	s1,88(sp)
    800045a8:	7c02                	ld	s8,32(sp)
    800045aa:	6ce2                	ld	s9,24(sp)
    800045ac:	6d42                	ld	s10,16(sp)
    800045ae:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800045b0:	8556                	mv	a0,s5
    800045b2:	00000097          	auipc	ra,0x0
    800045b6:	a7e080e7          	jalr	-1410(ra) # 80004030 <iupdate>

  return tot;
    800045ba:	0009851b          	sext.w	a0,s3
    800045be:	69a6                	ld	s3,72(sp)
}
    800045c0:	70a6                	ld	ra,104(sp)
    800045c2:	7406                	ld	s0,96(sp)
    800045c4:	6946                	ld	s2,80(sp)
    800045c6:	6a06                	ld	s4,64(sp)
    800045c8:	7ae2                	ld	s5,56(sp)
    800045ca:	7b42                	ld	s6,48(sp)
    800045cc:	7ba2                	ld	s7,40(sp)
    800045ce:	6165                	addi	sp,sp,112
    800045d0:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800045d2:	89da                	mv	s3,s6
    800045d4:	bff1                	j	800045b0 <writei+0xec>
    800045d6:	64e6                	ld	s1,88(sp)
    800045d8:	7c02                	ld	s8,32(sp)
    800045da:	6ce2                	ld	s9,24(sp)
    800045dc:	6d42                	ld	s10,16(sp)
    800045de:	6da2                	ld	s11,8(sp)
    800045e0:	bfc1                	j	800045b0 <writei+0xec>
    return -1;
    800045e2:	557d                	li	a0,-1
}
    800045e4:	8082                	ret
    return -1;
    800045e6:	557d                	li	a0,-1
    800045e8:	bfe1                	j	800045c0 <writei+0xfc>
    return -1;
    800045ea:	557d                	li	a0,-1
    800045ec:	bfd1                	j	800045c0 <writei+0xfc>

00000000800045ee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800045ee:	1141                	addi	sp,sp,-16
    800045f0:	e406                	sd	ra,8(sp)
    800045f2:	e022                	sd	s0,0(sp)
    800045f4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800045f6:	4639                	li	a2,14
    800045f8:	ffffd097          	auipc	ra,0xffffd
    800045fc:	80c080e7          	jalr	-2036(ra) # 80000e04 <strncmp>
}
    80004600:	60a2                	ld	ra,8(sp)
    80004602:	6402                	ld	s0,0(sp)
    80004604:	0141                	addi	sp,sp,16
    80004606:	8082                	ret

0000000080004608 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004608:	7139                	addi	sp,sp,-64
    8000460a:	fc06                	sd	ra,56(sp)
    8000460c:	f822                	sd	s0,48(sp)
    8000460e:	f426                	sd	s1,40(sp)
    80004610:	f04a                	sd	s2,32(sp)
    80004612:	ec4e                	sd	s3,24(sp)
    80004614:	e852                	sd	s4,16(sp)
    80004616:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004618:	04451703          	lh	a4,68(a0)
    8000461c:	4785                	li	a5,1
    8000461e:	00f71a63          	bne	a4,a5,80004632 <dirlookup+0x2a>
    80004622:	892a                	mv	s2,a0
    80004624:	89ae                	mv	s3,a1
    80004626:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004628:	457c                	lw	a5,76(a0)
    8000462a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000462c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000462e:	e79d                	bnez	a5,8000465c <dirlookup+0x54>
    80004630:	a8a5                	j	800046a8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004632:	00004517          	auipc	a0,0x4
    80004636:	ede50513          	addi	a0,a0,-290 # 80008510 <etext+0x510>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	f26080e7          	jalr	-218(ra) # 80000560 <panic>
      panic("dirlookup read");
    80004642:	00004517          	auipc	a0,0x4
    80004646:	ee650513          	addi	a0,a0,-282 # 80008528 <etext+0x528>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	f16080e7          	jalr	-234(ra) # 80000560 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004652:	24c1                	addiw	s1,s1,16
    80004654:	04c92783          	lw	a5,76(s2)
    80004658:	04f4f763          	bgeu	s1,a5,800046a6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000465c:	4741                	li	a4,16
    8000465e:	86a6                	mv	a3,s1
    80004660:	fc040613          	addi	a2,s0,-64
    80004664:	4581                	li	a1,0
    80004666:	854a                	mv	a0,s2
    80004668:	00000097          	auipc	ra,0x0
    8000466c:	d4c080e7          	jalr	-692(ra) # 800043b4 <readi>
    80004670:	47c1                	li	a5,16
    80004672:	fcf518e3          	bne	a0,a5,80004642 <dirlookup+0x3a>
    if(de.inum == 0)
    80004676:	fc045783          	lhu	a5,-64(s0)
    8000467a:	dfe1                	beqz	a5,80004652 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000467c:	fc240593          	addi	a1,s0,-62
    80004680:	854e                	mv	a0,s3
    80004682:	00000097          	auipc	ra,0x0
    80004686:	f6c080e7          	jalr	-148(ra) # 800045ee <namecmp>
    8000468a:	f561                	bnez	a0,80004652 <dirlookup+0x4a>
      if(poff)
    8000468c:	000a0463          	beqz	s4,80004694 <dirlookup+0x8c>
        *poff = off;
    80004690:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004694:	fc045583          	lhu	a1,-64(s0)
    80004698:	00092503          	lw	a0,0(s2)
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	720080e7          	jalr	1824(ra) # 80003dbc <iget>
    800046a4:	a011                	j	800046a8 <dirlookup+0xa0>
  return 0;
    800046a6:	4501                	li	a0,0
}
    800046a8:	70e2                	ld	ra,56(sp)
    800046aa:	7442                	ld	s0,48(sp)
    800046ac:	74a2                	ld	s1,40(sp)
    800046ae:	7902                	ld	s2,32(sp)
    800046b0:	69e2                	ld	s3,24(sp)
    800046b2:	6a42                	ld	s4,16(sp)
    800046b4:	6121                	addi	sp,sp,64
    800046b6:	8082                	ret

00000000800046b8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800046b8:	711d                	addi	sp,sp,-96
    800046ba:	ec86                	sd	ra,88(sp)
    800046bc:	e8a2                	sd	s0,80(sp)
    800046be:	e4a6                	sd	s1,72(sp)
    800046c0:	e0ca                	sd	s2,64(sp)
    800046c2:	fc4e                	sd	s3,56(sp)
    800046c4:	f852                	sd	s4,48(sp)
    800046c6:	f456                	sd	s5,40(sp)
    800046c8:	f05a                	sd	s6,32(sp)
    800046ca:	ec5e                	sd	s7,24(sp)
    800046cc:	e862                	sd	s8,16(sp)
    800046ce:	e466                	sd	s9,8(sp)
    800046d0:	1080                	addi	s0,sp,96
    800046d2:	84aa                	mv	s1,a0
    800046d4:	8b2e                	mv	s6,a1
    800046d6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800046d8:	00054703          	lbu	a4,0(a0)
    800046dc:	02f00793          	li	a5,47
    800046e0:	02f70263          	beq	a4,a5,80004704 <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800046e4:	ffffd097          	auipc	ra,0xffffd
    800046e8:	650080e7          	jalr	1616(ra) # 80001d34 <myproc>
    800046ec:	15053503          	ld	a0,336(a0)
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	9ce080e7          	jalr	-1586(ra) # 800040be <idup>
    800046f8:	8a2a                	mv	s4,a0
  while(*path == '/')
    800046fa:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800046fe:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004700:	4b85                	li	s7,1
    80004702:	a875                	j	800047be <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    80004704:	4585                	li	a1,1
    80004706:	4505                	li	a0,1
    80004708:	fffff097          	auipc	ra,0xfffff
    8000470c:	6b4080e7          	jalr	1716(ra) # 80003dbc <iget>
    80004710:	8a2a                	mv	s4,a0
    80004712:	b7e5                	j	800046fa <namex+0x42>
      iunlockput(ip);
    80004714:	8552                	mv	a0,s4
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	c4c080e7          	jalr	-948(ra) # 80004362 <iunlockput>
      return 0;
    8000471e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004720:	8552                	mv	a0,s4
    80004722:	60e6                	ld	ra,88(sp)
    80004724:	6446                	ld	s0,80(sp)
    80004726:	64a6                	ld	s1,72(sp)
    80004728:	6906                	ld	s2,64(sp)
    8000472a:	79e2                	ld	s3,56(sp)
    8000472c:	7a42                	ld	s4,48(sp)
    8000472e:	7aa2                	ld	s5,40(sp)
    80004730:	7b02                	ld	s6,32(sp)
    80004732:	6be2                	ld	s7,24(sp)
    80004734:	6c42                	ld	s8,16(sp)
    80004736:	6ca2                	ld	s9,8(sp)
    80004738:	6125                	addi	sp,sp,96
    8000473a:	8082                	ret
      iunlock(ip);
    8000473c:	8552                	mv	a0,s4
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	a84080e7          	jalr	-1404(ra) # 800041c2 <iunlock>
      return ip;
    80004746:	bfe9                	j	80004720 <namex+0x68>
      iunlockput(ip);
    80004748:	8552                	mv	a0,s4
    8000474a:	00000097          	auipc	ra,0x0
    8000474e:	c18080e7          	jalr	-1000(ra) # 80004362 <iunlockput>
      return 0;
    80004752:	8a4e                	mv	s4,s3
    80004754:	b7f1                	j	80004720 <namex+0x68>
  len = path - s;
    80004756:	40998633          	sub	a2,s3,s1
    8000475a:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    8000475e:	099c5863          	bge	s8,s9,800047ee <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004762:	4639                	li	a2,14
    80004764:	85a6                	mv	a1,s1
    80004766:	8556                	mv	a0,s5
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	628080e7          	jalr	1576(ra) # 80000d90 <memmove>
    80004770:	84ce                	mv	s1,s3
  while(*path == '/')
    80004772:	0004c783          	lbu	a5,0(s1)
    80004776:	01279763          	bne	a5,s2,80004784 <namex+0xcc>
    path++;
    8000477a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000477c:	0004c783          	lbu	a5,0(s1)
    80004780:	ff278de3          	beq	a5,s2,8000477a <namex+0xc2>
    ilock(ip);
    80004784:	8552                	mv	a0,s4
    80004786:	00000097          	auipc	ra,0x0
    8000478a:	976080e7          	jalr	-1674(ra) # 800040fc <ilock>
    if(ip->type != T_DIR){
    8000478e:	044a1783          	lh	a5,68(s4)
    80004792:	f97791e3          	bne	a5,s7,80004714 <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004796:	000b0563          	beqz	s6,800047a0 <namex+0xe8>
    8000479a:	0004c783          	lbu	a5,0(s1)
    8000479e:	dfd9                	beqz	a5,8000473c <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    800047a0:	4601                	li	a2,0
    800047a2:	85d6                	mv	a1,s5
    800047a4:	8552                	mv	a0,s4
    800047a6:	00000097          	auipc	ra,0x0
    800047aa:	e62080e7          	jalr	-414(ra) # 80004608 <dirlookup>
    800047ae:	89aa                	mv	s3,a0
    800047b0:	dd41                	beqz	a0,80004748 <namex+0x90>
    iunlockput(ip);
    800047b2:	8552                	mv	a0,s4
    800047b4:	00000097          	auipc	ra,0x0
    800047b8:	bae080e7          	jalr	-1106(ra) # 80004362 <iunlockput>
    ip = next;
    800047bc:	8a4e                	mv	s4,s3
  while(*path == '/')
    800047be:	0004c783          	lbu	a5,0(s1)
    800047c2:	01279763          	bne	a5,s2,800047d0 <namex+0x118>
    path++;
    800047c6:	0485                	addi	s1,s1,1
  while(*path == '/')
    800047c8:	0004c783          	lbu	a5,0(s1)
    800047cc:	ff278de3          	beq	a5,s2,800047c6 <namex+0x10e>
  if(*path == 0)
    800047d0:	cb9d                	beqz	a5,80004806 <namex+0x14e>
  while(*path != '/' && *path != 0)
    800047d2:	0004c783          	lbu	a5,0(s1)
    800047d6:	89a6                	mv	s3,s1
  len = path - s;
    800047d8:	4c81                	li	s9,0
    800047da:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800047dc:	01278963          	beq	a5,s2,800047ee <namex+0x136>
    800047e0:	dbbd                	beqz	a5,80004756 <namex+0x9e>
    path++;
    800047e2:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800047e4:	0009c783          	lbu	a5,0(s3)
    800047e8:	ff279ce3          	bne	a5,s2,800047e0 <namex+0x128>
    800047ec:	b7ad                	j	80004756 <namex+0x9e>
    memmove(name, s, len);
    800047ee:	2601                	sext.w	a2,a2
    800047f0:	85a6                	mv	a1,s1
    800047f2:	8556                	mv	a0,s5
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	59c080e7          	jalr	1436(ra) # 80000d90 <memmove>
    name[len] = 0;
    800047fc:	9cd6                	add	s9,s9,s5
    800047fe:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004802:	84ce                	mv	s1,s3
    80004804:	b7bd                	j	80004772 <namex+0xba>
  if(nameiparent){
    80004806:	f00b0de3          	beqz	s6,80004720 <namex+0x68>
    iput(ip);
    8000480a:	8552                	mv	a0,s4
    8000480c:	00000097          	auipc	ra,0x0
    80004810:	aae080e7          	jalr	-1362(ra) # 800042ba <iput>
    return 0;
    80004814:	4a01                	li	s4,0
    80004816:	b729                	j	80004720 <namex+0x68>

0000000080004818 <dirlink>:
{
    80004818:	7139                	addi	sp,sp,-64
    8000481a:	fc06                	sd	ra,56(sp)
    8000481c:	f822                	sd	s0,48(sp)
    8000481e:	f04a                	sd	s2,32(sp)
    80004820:	ec4e                	sd	s3,24(sp)
    80004822:	e852                	sd	s4,16(sp)
    80004824:	0080                	addi	s0,sp,64
    80004826:	892a                	mv	s2,a0
    80004828:	8a2e                	mv	s4,a1
    8000482a:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000482c:	4601                	li	a2,0
    8000482e:	00000097          	auipc	ra,0x0
    80004832:	dda080e7          	jalr	-550(ra) # 80004608 <dirlookup>
    80004836:	ed25                	bnez	a0,800048ae <dirlink+0x96>
    80004838:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000483a:	04c92483          	lw	s1,76(s2)
    8000483e:	c49d                	beqz	s1,8000486c <dirlink+0x54>
    80004840:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004842:	4741                	li	a4,16
    80004844:	86a6                	mv	a3,s1
    80004846:	fc040613          	addi	a2,s0,-64
    8000484a:	4581                	li	a1,0
    8000484c:	854a                	mv	a0,s2
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	b66080e7          	jalr	-1178(ra) # 800043b4 <readi>
    80004856:	47c1                	li	a5,16
    80004858:	06f51163          	bne	a0,a5,800048ba <dirlink+0xa2>
    if(de.inum == 0)
    8000485c:	fc045783          	lhu	a5,-64(s0)
    80004860:	c791                	beqz	a5,8000486c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004862:	24c1                	addiw	s1,s1,16
    80004864:	04c92783          	lw	a5,76(s2)
    80004868:	fcf4ede3          	bltu	s1,a5,80004842 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000486c:	4639                	li	a2,14
    8000486e:	85d2                	mv	a1,s4
    80004870:	fc240513          	addi	a0,s0,-62
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	5c6080e7          	jalr	1478(ra) # 80000e3a <strncpy>
  de.inum = inum;
    8000487c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004880:	4741                	li	a4,16
    80004882:	86a6                	mv	a3,s1
    80004884:	fc040613          	addi	a2,s0,-64
    80004888:	4581                	li	a1,0
    8000488a:	854a                	mv	a0,s2
    8000488c:	00000097          	auipc	ra,0x0
    80004890:	c38080e7          	jalr	-968(ra) # 800044c4 <writei>
    80004894:	1541                	addi	a0,a0,-16
    80004896:	00a03533          	snez	a0,a0
    8000489a:	40a00533          	neg	a0,a0
    8000489e:	74a2                	ld	s1,40(sp)
}
    800048a0:	70e2                	ld	ra,56(sp)
    800048a2:	7442                	ld	s0,48(sp)
    800048a4:	7902                	ld	s2,32(sp)
    800048a6:	69e2                	ld	s3,24(sp)
    800048a8:	6a42                	ld	s4,16(sp)
    800048aa:	6121                	addi	sp,sp,64
    800048ac:	8082                	ret
    iput(ip);
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	a0c080e7          	jalr	-1524(ra) # 800042ba <iput>
    return -1;
    800048b6:	557d                	li	a0,-1
    800048b8:	b7e5                	j	800048a0 <dirlink+0x88>
      panic("dirlink read");
    800048ba:	00004517          	auipc	a0,0x4
    800048be:	c7e50513          	addi	a0,a0,-898 # 80008538 <etext+0x538>
    800048c2:	ffffc097          	auipc	ra,0xffffc
    800048c6:	c9e080e7          	jalr	-866(ra) # 80000560 <panic>

00000000800048ca <namei>:

struct inode*
namei(char *path)
{
    800048ca:	1101                	addi	sp,sp,-32
    800048cc:	ec06                	sd	ra,24(sp)
    800048ce:	e822                	sd	s0,16(sp)
    800048d0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800048d2:	fe040613          	addi	a2,s0,-32
    800048d6:	4581                	li	a1,0
    800048d8:	00000097          	auipc	ra,0x0
    800048dc:	de0080e7          	jalr	-544(ra) # 800046b8 <namex>
}
    800048e0:	60e2                	ld	ra,24(sp)
    800048e2:	6442                	ld	s0,16(sp)
    800048e4:	6105                	addi	sp,sp,32
    800048e6:	8082                	ret

00000000800048e8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800048e8:	1141                	addi	sp,sp,-16
    800048ea:	e406                	sd	ra,8(sp)
    800048ec:	e022                	sd	s0,0(sp)
    800048ee:	0800                	addi	s0,sp,16
    800048f0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800048f2:	4585                	li	a1,1
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	dc4080e7          	jalr	-572(ra) # 800046b8 <namex>
}
    800048fc:	60a2                	ld	ra,8(sp)
    800048fe:	6402                	ld	s0,0(sp)
    80004900:	0141                	addi	sp,sp,16
    80004902:	8082                	ret

0000000080004904 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004904:	1101                	addi	sp,sp,-32
    80004906:	ec06                	sd	ra,24(sp)
    80004908:	e822                	sd	s0,16(sp)
    8000490a:	e426                	sd	s1,8(sp)
    8000490c:	e04a                	sd	s2,0(sp)
    8000490e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004910:	00022917          	auipc	s2,0x22
    80004914:	60090913          	addi	s2,s2,1536 # 80026f10 <log>
    80004918:	01892583          	lw	a1,24(s2)
    8000491c:	02892503          	lw	a0,40(s2)
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	fa8080e7          	jalr	-88(ra) # 800038c8 <bread>
    80004928:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000492a:	02c92603          	lw	a2,44(s2)
    8000492e:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004930:	00c05f63          	blez	a2,8000494e <write_head+0x4a>
    80004934:	00022717          	auipc	a4,0x22
    80004938:	60c70713          	addi	a4,a4,1548 # 80026f40 <log+0x30>
    8000493c:	87aa                	mv	a5,a0
    8000493e:	060a                	slli	a2,a2,0x2
    80004940:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004942:	4314                	lw	a3,0(a4)
    80004944:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004946:	0711                	addi	a4,a4,4
    80004948:	0791                	addi	a5,a5,4
    8000494a:	fec79ce3          	bne	a5,a2,80004942 <write_head+0x3e>
  }
  bwrite(buf);
    8000494e:	8526                	mv	a0,s1
    80004950:	fffff097          	auipc	ra,0xfffff
    80004954:	06a080e7          	jalr	106(ra) # 800039ba <bwrite>
  brelse(buf);
    80004958:	8526                	mv	a0,s1
    8000495a:	fffff097          	auipc	ra,0xfffff
    8000495e:	09e080e7          	jalr	158(ra) # 800039f8 <brelse>
}
    80004962:	60e2                	ld	ra,24(sp)
    80004964:	6442                	ld	s0,16(sp)
    80004966:	64a2                	ld	s1,8(sp)
    80004968:	6902                	ld	s2,0(sp)
    8000496a:	6105                	addi	sp,sp,32
    8000496c:	8082                	ret

000000008000496e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000496e:	00022797          	auipc	a5,0x22
    80004972:	5ce7a783          	lw	a5,1486(a5) # 80026f3c <log+0x2c>
    80004976:	0af05d63          	blez	a5,80004a30 <install_trans+0xc2>
{
    8000497a:	7139                	addi	sp,sp,-64
    8000497c:	fc06                	sd	ra,56(sp)
    8000497e:	f822                	sd	s0,48(sp)
    80004980:	f426                	sd	s1,40(sp)
    80004982:	f04a                	sd	s2,32(sp)
    80004984:	ec4e                	sd	s3,24(sp)
    80004986:	e852                	sd	s4,16(sp)
    80004988:	e456                	sd	s5,8(sp)
    8000498a:	e05a                	sd	s6,0(sp)
    8000498c:	0080                	addi	s0,sp,64
    8000498e:	8b2a                	mv	s6,a0
    80004990:	00022a97          	auipc	s5,0x22
    80004994:	5b0a8a93          	addi	s5,s5,1456 # 80026f40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004998:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000499a:	00022997          	auipc	s3,0x22
    8000499e:	57698993          	addi	s3,s3,1398 # 80026f10 <log>
    800049a2:	a00d                	j	800049c4 <install_trans+0x56>
    brelse(lbuf);
    800049a4:	854a                	mv	a0,s2
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	052080e7          	jalr	82(ra) # 800039f8 <brelse>
    brelse(dbuf);
    800049ae:	8526                	mv	a0,s1
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	048080e7          	jalr	72(ra) # 800039f8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800049b8:	2a05                	addiw	s4,s4,1
    800049ba:	0a91                	addi	s5,s5,4
    800049bc:	02c9a783          	lw	a5,44(s3)
    800049c0:	04fa5e63          	bge	s4,a5,80004a1c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800049c4:	0189a583          	lw	a1,24(s3)
    800049c8:	014585bb          	addw	a1,a1,s4
    800049cc:	2585                	addiw	a1,a1,1
    800049ce:	0289a503          	lw	a0,40(s3)
    800049d2:	fffff097          	auipc	ra,0xfffff
    800049d6:	ef6080e7          	jalr	-266(ra) # 800038c8 <bread>
    800049da:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800049dc:	000aa583          	lw	a1,0(s5)
    800049e0:	0289a503          	lw	a0,40(s3)
    800049e4:	fffff097          	auipc	ra,0xfffff
    800049e8:	ee4080e7          	jalr	-284(ra) # 800038c8 <bread>
    800049ec:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800049ee:	40000613          	li	a2,1024
    800049f2:	05890593          	addi	a1,s2,88
    800049f6:	05850513          	addi	a0,a0,88
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	396080e7          	jalr	918(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004a02:	8526                	mv	a0,s1
    80004a04:	fffff097          	auipc	ra,0xfffff
    80004a08:	fb6080e7          	jalr	-74(ra) # 800039ba <bwrite>
    if(recovering == 0)
    80004a0c:	f80b1ce3          	bnez	s6,800049a4 <install_trans+0x36>
      bunpin(dbuf);
    80004a10:	8526                	mv	a0,s1
    80004a12:	fffff097          	auipc	ra,0xfffff
    80004a16:	0be080e7          	jalr	190(ra) # 80003ad0 <bunpin>
    80004a1a:	b769                	j	800049a4 <install_trans+0x36>
}
    80004a1c:	70e2                	ld	ra,56(sp)
    80004a1e:	7442                	ld	s0,48(sp)
    80004a20:	74a2                	ld	s1,40(sp)
    80004a22:	7902                	ld	s2,32(sp)
    80004a24:	69e2                	ld	s3,24(sp)
    80004a26:	6a42                	ld	s4,16(sp)
    80004a28:	6aa2                	ld	s5,8(sp)
    80004a2a:	6b02                	ld	s6,0(sp)
    80004a2c:	6121                	addi	sp,sp,64
    80004a2e:	8082                	ret
    80004a30:	8082                	ret

0000000080004a32 <initlog>:
{
    80004a32:	7179                	addi	sp,sp,-48
    80004a34:	f406                	sd	ra,40(sp)
    80004a36:	f022                	sd	s0,32(sp)
    80004a38:	ec26                	sd	s1,24(sp)
    80004a3a:	e84a                	sd	s2,16(sp)
    80004a3c:	e44e                	sd	s3,8(sp)
    80004a3e:	1800                	addi	s0,sp,48
    80004a40:	892a                	mv	s2,a0
    80004a42:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004a44:	00022497          	auipc	s1,0x22
    80004a48:	4cc48493          	addi	s1,s1,1228 # 80026f10 <log>
    80004a4c:	00004597          	auipc	a1,0x4
    80004a50:	afc58593          	addi	a1,a1,-1284 # 80008548 <etext+0x548>
    80004a54:	8526                	mv	a0,s1
    80004a56:	ffffc097          	auipc	ra,0xffffc
    80004a5a:	152080e7          	jalr	338(ra) # 80000ba8 <initlock>
  log.start = sb->logstart;
    80004a5e:	0149a583          	lw	a1,20(s3)
    80004a62:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004a64:	0109a783          	lw	a5,16(s3)
    80004a68:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004a6a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004a6e:	854a                	mv	a0,s2
    80004a70:	fffff097          	auipc	ra,0xfffff
    80004a74:	e58080e7          	jalr	-424(ra) # 800038c8 <bread>
  log.lh.n = lh->n;
    80004a78:	4d30                	lw	a2,88(a0)
    80004a7a:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004a7c:	00c05f63          	blez	a2,80004a9a <initlog+0x68>
    80004a80:	87aa                	mv	a5,a0
    80004a82:	00022717          	auipc	a4,0x22
    80004a86:	4be70713          	addi	a4,a4,1214 # 80026f40 <log+0x30>
    80004a8a:	060a                	slli	a2,a2,0x2
    80004a8c:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004a8e:	4ff4                	lw	a3,92(a5)
    80004a90:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004a92:	0791                	addi	a5,a5,4
    80004a94:	0711                	addi	a4,a4,4
    80004a96:	fec79ce3          	bne	a5,a2,80004a8e <initlog+0x5c>
  brelse(buf);
    80004a9a:	fffff097          	auipc	ra,0xfffff
    80004a9e:	f5e080e7          	jalr	-162(ra) # 800039f8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004aa2:	4505                	li	a0,1
    80004aa4:	00000097          	auipc	ra,0x0
    80004aa8:	eca080e7          	jalr	-310(ra) # 8000496e <install_trans>
  log.lh.n = 0;
    80004aac:	00022797          	auipc	a5,0x22
    80004ab0:	4807a823          	sw	zero,1168(a5) # 80026f3c <log+0x2c>
  write_head(); // clear the log
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	e50080e7          	jalr	-432(ra) # 80004904 <write_head>
}
    80004abc:	70a2                	ld	ra,40(sp)
    80004abe:	7402                	ld	s0,32(sp)
    80004ac0:	64e2                	ld	s1,24(sp)
    80004ac2:	6942                	ld	s2,16(sp)
    80004ac4:	69a2                	ld	s3,8(sp)
    80004ac6:	6145                	addi	sp,sp,48
    80004ac8:	8082                	ret

0000000080004aca <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004aca:	1101                	addi	sp,sp,-32
    80004acc:	ec06                	sd	ra,24(sp)
    80004ace:	e822                	sd	s0,16(sp)
    80004ad0:	e426                	sd	s1,8(sp)
    80004ad2:	e04a                	sd	s2,0(sp)
    80004ad4:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004ad6:	00022517          	auipc	a0,0x22
    80004ada:	43a50513          	addi	a0,a0,1082 # 80026f10 <log>
    80004ade:	ffffc097          	auipc	ra,0xffffc
    80004ae2:	15a080e7          	jalr	346(ra) # 80000c38 <acquire>
  while(1){
    if(log.committing){
    80004ae6:	00022497          	auipc	s1,0x22
    80004aea:	42a48493          	addi	s1,s1,1066 # 80026f10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004aee:	4979                	li	s2,30
    80004af0:	a039                	j	80004afe <begin_op+0x34>
      sleep(&log, &log.lock);
    80004af2:	85a6                	mv	a1,s1
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffe097          	auipc	ra,0xffffe
    80004afa:	a60080e7          	jalr	-1440(ra) # 80002556 <sleep>
    if(log.committing){
    80004afe:	50dc                	lw	a5,36(s1)
    80004b00:	fbed                	bnez	a5,80004af2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004b02:	5098                	lw	a4,32(s1)
    80004b04:	2705                	addiw	a4,a4,1
    80004b06:	0027179b          	slliw	a5,a4,0x2
    80004b0a:	9fb9                	addw	a5,a5,a4
    80004b0c:	0017979b          	slliw	a5,a5,0x1
    80004b10:	54d4                	lw	a3,44(s1)
    80004b12:	9fb5                	addw	a5,a5,a3
    80004b14:	00f95963          	bge	s2,a5,80004b26 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004b18:	85a6                	mv	a1,s1
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	ffffe097          	auipc	ra,0xffffe
    80004b20:	a3a080e7          	jalr	-1478(ra) # 80002556 <sleep>
    80004b24:	bfe9                	j	80004afe <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004b26:	00022517          	auipc	a0,0x22
    80004b2a:	3ea50513          	addi	a0,a0,1002 # 80026f10 <log>
    80004b2e:	d118                	sw	a4,32(a0)
      release(&log.lock);
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	1bc080e7          	jalr	444(ra) # 80000cec <release>
      break;
    }
  }
}
    80004b38:	60e2                	ld	ra,24(sp)
    80004b3a:	6442                	ld	s0,16(sp)
    80004b3c:	64a2                	ld	s1,8(sp)
    80004b3e:	6902                	ld	s2,0(sp)
    80004b40:	6105                	addi	sp,sp,32
    80004b42:	8082                	ret

0000000080004b44 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004b44:	7139                	addi	sp,sp,-64
    80004b46:	fc06                	sd	ra,56(sp)
    80004b48:	f822                	sd	s0,48(sp)
    80004b4a:	f426                	sd	s1,40(sp)
    80004b4c:	f04a                	sd	s2,32(sp)
    80004b4e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004b50:	00022497          	auipc	s1,0x22
    80004b54:	3c048493          	addi	s1,s1,960 # 80026f10 <log>
    80004b58:	8526                	mv	a0,s1
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	0de080e7          	jalr	222(ra) # 80000c38 <acquire>
  log.outstanding -= 1;
    80004b62:	509c                	lw	a5,32(s1)
    80004b64:	37fd                	addiw	a5,a5,-1
    80004b66:	0007891b          	sext.w	s2,a5
    80004b6a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004b6c:	50dc                	lw	a5,36(s1)
    80004b6e:	e7b9                	bnez	a5,80004bbc <end_op+0x78>
    panic("log.committing");
  if(log.outstanding == 0){
    80004b70:	06091163          	bnez	s2,80004bd2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004b74:	00022497          	auipc	s1,0x22
    80004b78:	39c48493          	addi	s1,s1,924 # 80026f10 <log>
    80004b7c:	4785                	li	a5,1
    80004b7e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004b80:	8526                	mv	a0,s1
    80004b82:	ffffc097          	auipc	ra,0xffffc
    80004b86:	16a080e7          	jalr	362(ra) # 80000cec <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004b8a:	54dc                	lw	a5,44(s1)
    80004b8c:	06f04763          	bgtz	a5,80004bfa <end_op+0xb6>
    acquire(&log.lock);
    80004b90:	00022497          	auipc	s1,0x22
    80004b94:	38048493          	addi	s1,s1,896 # 80026f10 <log>
    80004b98:	8526                	mv	a0,s1
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	09e080e7          	jalr	158(ra) # 80000c38 <acquire>
    log.committing = 0;
    80004ba2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004ba6:	8526                	mv	a0,s1
    80004ba8:	ffffe097          	auipc	ra,0xffffe
    80004bac:	a2c080e7          	jalr	-1492(ra) # 800025d4 <wakeup>
    release(&log.lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	13a080e7          	jalr	314(ra) # 80000cec <release>
}
    80004bba:	a815                	j	80004bee <end_op+0xaa>
    80004bbc:	ec4e                	sd	s3,24(sp)
    80004bbe:	e852                	sd	s4,16(sp)
    80004bc0:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80004bc2:	00004517          	auipc	a0,0x4
    80004bc6:	98e50513          	addi	a0,a0,-1650 # 80008550 <etext+0x550>
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	996080e7          	jalr	-1642(ra) # 80000560 <panic>
    wakeup(&log);
    80004bd2:	00022497          	auipc	s1,0x22
    80004bd6:	33e48493          	addi	s1,s1,830 # 80026f10 <log>
    80004bda:	8526                	mv	a0,s1
    80004bdc:	ffffe097          	auipc	ra,0xffffe
    80004be0:	9f8080e7          	jalr	-1544(ra) # 800025d4 <wakeup>
  release(&log.lock);
    80004be4:	8526                	mv	a0,s1
    80004be6:	ffffc097          	auipc	ra,0xffffc
    80004bea:	106080e7          	jalr	262(ra) # 80000cec <release>
}
    80004bee:	70e2                	ld	ra,56(sp)
    80004bf0:	7442                	ld	s0,48(sp)
    80004bf2:	74a2                	ld	s1,40(sp)
    80004bf4:	7902                	ld	s2,32(sp)
    80004bf6:	6121                	addi	sp,sp,64
    80004bf8:	8082                	ret
    80004bfa:	ec4e                	sd	s3,24(sp)
    80004bfc:	e852                	sd	s4,16(sp)
    80004bfe:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c00:	00022a97          	auipc	s5,0x22
    80004c04:	340a8a93          	addi	s5,s5,832 # 80026f40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004c08:	00022a17          	auipc	s4,0x22
    80004c0c:	308a0a13          	addi	s4,s4,776 # 80026f10 <log>
    80004c10:	018a2583          	lw	a1,24(s4)
    80004c14:	012585bb          	addw	a1,a1,s2
    80004c18:	2585                	addiw	a1,a1,1
    80004c1a:	028a2503          	lw	a0,40(s4)
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	caa080e7          	jalr	-854(ra) # 800038c8 <bread>
    80004c26:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004c28:	000aa583          	lw	a1,0(s5)
    80004c2c:	028a2503          	lw	a0,40(s4)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	c98080e7          	jalr	-872(ra) # 800038c8 <bread>
    80004c38:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004c3a:	40000613          	li	a2,1024
    80004c3e:	05850593          	addi	a1,a0,88
    80004c42:	05848513          	addi	a0,s1,88
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	14a080e7          	jalr	330(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    80004c4e:	8526                	mv	a0,s1
    80004c50:	fffff097          	auipc	ra,0xfffff
    80004c54:	d6a080e7          	jalr	-662(ra) # 800039ba <bwrite>
    brelse(from);
    80004c58:	854e                	mv	a0,s3
    80004c5a:	fffff097          	auipc	ra,0xfffff
    80004c5e:	d9e080e7          	jalr	-610(ra) # 800039f8 <brelse>
    brelse(to);
    80004c62:	8526                	mv	a0,s1
    80004c64:	fffff097          	auipc	ra,0xfffff
    80004c68:	d94080e7          	jalr	-620(ra) # 800039f8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004c6c:	2905                	addiw	s2,s2,1
    80004c6e:	0a91                	addi	s5,s5,4
    80004c70:	02ca2783          	lw	a5,44(s4)
    80004c74:	f8f94ee3          	blt	s2,a5,80004c10 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004c78:	00000097          	auipc	ra,0x0
    80004c7c:	c8c080e7          	jalr	-884(ra) # 80004904 <write_head>
    install_trans(0); // Now install writes to home locations
    80004c80:	4501                	li	a0,0
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	cec080e7          	jalr	-788(ra) # 8000496e <install_trans>
    log.lh.n = 0;
    80004c8a:	00022797          	auipc	a5,0x22
    80004c8e:	2a07a923          	sw	zero,690(a5) # 80026f3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004c92:	00000097          	auipc	ra,0x0
    80004c96:	c72080e7          	jalr	-910(ra) # 80004904 <write_head>
    80004c9a:	69e2                	ld	s3,24(sp)
    80004c9c:	6a42                	ld	s4,16(sp)
    80004c9e:	6aa2                	ld	s5,8(sp)
    80004ca0:	bdc5                	j	80004b90 <end_op+0x4c>

0000000080004ca2 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004ca2:	1101                	addi	sp,sp,-32
    80004ca4:	ec06                	sd	ra,24(sp)
    80004ca6:	e822                	sd	s0,16(sp)
    80004ca8:	e426                	sd	s1,8(sp)
    80004caa:	e04a                	sd	s2,0(sp)
    80004cac:	1000                	addi	s0,sp,32
    80004cae:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004cb0:	00022917          	auipc	s2,0x22
    80004cb4:	26090913          	addi	s2,s2,608 # 80026f10 <log>
    80004cb8:	854a                	mv	a0,s2
    80004cba:	ffffc097          	auipc	ra,0xffffc
    80004cbe:	f7e080e7          	jalr	-130(ra) # 80000c38 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004cc2:	02c92603          	lw	a2,44(s2)
    80004cc6:	47f5                	li	a5,29
    80004cc8:	06c7c563          	blt	a5,a2,80004d32 <log_write+0x90>
    80004ccc:	00022797          	auipc	a5,0x22
    80004cd0:	2607a783          	lw	a5,608(a5) # 80026f2c <log+0x1c>
    80004cd4:	37fd                	addiw	a5,a5,-1
    80004cd6:	04f65e63          	bge	a2,a5,80004d32 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004cda:	00022797          	auipc	a5,0x22
    80004cde:	2567a783          	lw	a5,598(a5) # 80026f30 <log+0x20>
    80004ce2:	06f05063          	blez	a5,80004d42 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004ce6:	4781                	li	a5,0
    80004ce8:	06c05563          	blez	a2,80004d52 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004cec:	44cc                	lw	a1,12(s1)
    80004cee:	00022717          	auipc	a4,0x22
    80004cf2:	25270713          	addi	a4,a4,594 # 80026f40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004cf6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004cf8:	4314                	lw	a3,0(a4)
    80004cfa:	04b68c63          	beq	a3,a1,80004d52 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004cfe:	2785                	addiw	a5,a5,1
    80004d00:	0711                	addi	a4,a4,4
    80004d02:	fef61be3          	bne	a2,a5,80004cf8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004d06:	0621                	addi	a2,a2,8
    80004d08:	060a                	slli	a2,a2,0x2
    80004d0a:	00022797          	auipc	a5,0x22
    80004d0e:	20678793          	addi	a5,a5,518 # 80026f10 <log>
    80004d12:	97b2                	add	a5,a5,a2
    80004d14:	44d8                	lw	a4,12(s1)
    80004d16:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004d18:	8526                	mv	a0,s1
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	d7a080e7          	jalr	-646(ra) # 80003a94 <bpin>
    log.lh.n++;
    80004d22:	00022717          	auipc	a4,0x22
    80004d26:	1ee70713          	addi	a4,a4,494 # 80026f10 <log>
    80004d2a:	575c                	lw	a5,44(a4)
    80004d2c:	2785                	addiw	a5,a5,1
    80004d2e:	d75c                	sw	a5,44(a4)
    80004d30:	a82d                	j	80004d6a <log_write+0xc8>
    panic("too big a transaction");
    80004d32:	00004517          	auipc	a0,0x4
    80004d36:	82e50513          	addi	a0,a0,-2002 # 80008560 <etext+0x560>
    80004d3a:	ffffc097          	auipc	ra,0xffffc
    80004d3e:	826080e7          	jalr	-2010(ra) # 80000560 <panic>
    panic("log_write outside of trans");
    80004d42:	00004517          	auipc	a0,0x4
    80004d46:	83650513          	addi	a0,a0,-1994 # 80008578 <etext+0x578>
    80004d4a:	ffffc097          	auipc	ra,0xffffc
    80004d4e:	816080e7          	jalr	-2026(ra) # 80000560 <panic>
  log.lh.block[i] = b->blockno;
    80004d52:	00878693          	addi	a3,a5,8
    80004d56:	068a                	slli	a3,a3,0x2
    80004d58:	00022717          	auipc	a4,0x22
    80004d5c:	1b870713          	addi	a4,a4,440 # 80026f10 <log>
    80004d60:	9736                	add	a4,a4,a3
    80004d62:	44d4                	lw	a3,12(s1)
    80004d64:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004d66:	faf609e3          	beq	a2,a5,80004d18 <log_write+0x76>
  }
  release(&log.lock);
    80004d6a:	00022517          	auipc	a0,0x22
    80004d6e:	1a650513          	addi	a0,a0,422 # 80026f10 <log>
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	f7a080e7          	jalr	-134(ra) # 80000cec <release>
}
    80004d7a:	60e2                	ld	ra,24(sp)
    80004d7c:	6442                	ld	s0,16(sp)
    80004d7e:	64a2                	ld	s1,8(sp)
    80004d80:	6902                	ld	s2,0(sp)
    80004d82:	6105                	addi	sp,sp,32
    80004d84:	8082                	ret

0000000080004d86 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004d86:	1101                	addi	sp,sp,-32
    80004d88:	ec06                	sd	ra,24(sp)
    80004d8a:	e822                	sd	s0,16(sp)
    80004d8c:	e426                	sd	s1,8(sp)
    80004d8e:	e04a                	sd	s2,0(sp)
    80004d90:	1000                	addi	s0,sp,32
    80004d92:	84aa                	mv	s1,a0
    80004d94:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004d96:	00004597          	auipc	a1,0x4
    80004d9a:	80258593          	addi	a1,a1,-2046 # 80008598 <etext+0x598>
    80004d9e:	0521                	addi	a0,a0,8
    80004da0:	ffffc097          	auipc	ra,0xffffc
    80004da4:	e08080e7          	jalr	-504(ra) # 80000ba8 <initlock>
  lk->name = name;
    80004da8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004dac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004db0:	0204a423          	sw	zero,40(s1)
}
    80004db4:	60e2                	ld	ra,24(sp)
    80004db6:	6442                	ld	s0,16(sp)
    80004db8:	64a2                	ld	s1,8(sp)
    80004dba:	6902                	ld	s2,0(sp)
    80004dbc:	6105                	addi	sp,sp,32
    80004dbe:	8082                	ret

0000000080004dc0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004dc0:	1101                	addi	sp,sp,-32
    80004dc2:	ec06                	sd	ra,24(sp)
    80004dc4:	e822                	sd	s0,16(sp)
    80004dc6:	e426                	sd	s1,8(sp)
    80004dc8:	e04a                	sd	s2,0(sp)
    80004dca:	1000                	addi	s0,sp,32
    80004dcc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004dce:	00850913          	addi	s2,a0,8
    80004dd2:	854a                	mv	a0,s2
    80004dd4:	ffffc097          	auipc	ra,0xffffc
    80004dd8:	e64080e7          	jalr	-412(ra) # 80000c38 <acquire>
  while (lk->locked) {
    80004ddc:	409c                	lw	a5,0(s1)
    80004dde:	cb89                	beqz	a5,80004df0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004de0:	85ca                	mv	a1,s2
    80004de2:	8526                	mv	a0,s1
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	772080e7          	jalr	1906(ra) # 80002556 <sleep>
  while (lk->locked) {
    80004dec:	409c                	lw	a5,0(s1)
    80004dee:	fbed                	bnez	a5,80004de0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004df0:	4785                	li	a5,1
    80004df2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	f40080e7          	jalr	-192(ra) # 80001d34 <myproc>
    80004dfc:	591c                	lw	a5,48(a0)
    80004dfe:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004e00:	854a                	mv	a0,s2
    80004e02:	ffffc097          	auipc	ra,0xffffc
    80004e06:	eea080e7          	jalr	-278(ra) # 80000cec <release>
}
    80004e0a:	60e2                	ld	ra,24(sp)
    80004e0c:	6442                	ld	s0,16(sp)
    80004e0e:	64a2                	ld	s1,8(sp)
    80004e10:	6902                	ld	s2,0(sp)
    80004e12:	6105                	addi	sp,sp,32
    80004e14:	8082                	ret

0000000080004e16 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004e16:	1101                	addi	sp,sp,-32
    80004e18:	ec06                	sd	ra,24(sp)
    80004e1a:	e822                	sd	s0,16(sp)
    80004e1c:	e426                	sd	s1,8(sp)
    80004e1e:	e04a                	sd	s2,0(sp)
    80004e20:	1000                	addi	s0,sp,32
    80004e22:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004e24:	00850913          	addi	s2,a0,8
    80004e28:	854a                	mv	a0,s2
    80004e2a:	ffffc097          	auipc	ra,0xffffc
    80004e2e:	e0e080e7          	jalr	-498(ra) # 80000c38 <acquire>
  lk->locked = 0;
    80004e32:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004e36:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004e3a:	8526                	mv	a0,s1
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	798080e7          	jalr	1944(ra) # 800025d4 <wakeup>
  release(&lk->lk);
    80004e44:	854a                	mv	a0,s2
    80004e46:	ffffc097          	auipc	ra,0xffffc
    80004e4a:	ea6080e7          	jalr	-346(ra) # 80000cec <release>
}
    80004e4e:	60e2                	ld	ra,24(sp)
    80004e50:	6442                	ld	s0,16(sp)
    80004e52:	64a2                	ld	s1,8(sp)
    80004e54:	6902                	ld	s2,0(sp)
    80004e56:	6105                	addi	sp,sp,32
    80004e58:	8082                	ret

0000000080004e5a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004e5a:	7179                	addi	sp,sp,-48
    80004e5c:	f406                	sd	ra,40(sp)
    80004e5e:	f022                	sd	s0,32(sp)
    80004e60:	ec26                	sd	s1,24(sp)
    80004e62:	e84a                	sd	s2,16(sp)
    80004e64:	1800                	addi	s0,sp,48
    80004e66:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004e68:	00850913          	addi	s2,a0,8
    80004e6c:	854a                	mv	a0,s2
    80004e6e:	ffffc097          	auipc	ra,0xffffc
    80004e72:	dca080e7          	jalr	-566(ra) # 80000c38 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e76:	409c                	lw	a5,0(s1)
    80004e78:	ef91                	bnez	a5,80004e94 <holdingsleep+0x3a>
    80004e7a:	4481                	li	s1,0
  release(&lk->lk);
    80004e7c:	854a                	mv	a0,s2
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	e6e080e7          	jalr	-402(ra) # 80000cec <release>
  return r;
}
    80004e86:	8526                	mv	a0,s1
    80004e88:	70a2                	ld	ra,40(sp)
    80004e8a:	7402                	ld	s0,32(sp)
    80004e8c:	64e2                	ld	s1,24(sp)
    80004e8e:	6942                	ld	s2,16(sp)
    80004e90:	6145                	addi	sp,sp,48
    80004e92:	8082                	ret
    80004e94:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004e96:	0284a983          	lw	s3,40(s1)
    80004e9a:	ffffd097          	auipc	ra,0xffffd
    80004e9e:	e9a080e7          	jalr	-358(ra) # 80001d34 <myproc>
    80004ea2:	5904                	lw	s1,48(a0)
    80004ea4:	413484b3          	sub	s1,s1,s3
    80004ea8:	0014b493          	seqz	s1,s1
    80004eac:	69a2                	ld	s3,8(sp)
    80004eae:	b7f9                	j	80004e7c <holdingsleep+0x22>

0000000080004eb0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004eb0:	1141                	addi	sp,sp,-16
    80004eb2:	e406                	sd	ra,8(sp)
    80004eb4:	e022                	sd	s0,0(sp)
    80004eb6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004eb8:	00003597          	auipc	a1,0x3
    80004ebc:	6f058593          	addi	a1,a1,1776 # 800085a8 <etext+0x5a8>
    80004ec0:	00022517          	auipc	a0,0x22
    80004ec4:	19850513          	addi	a0,a0,408 # 80027058 <ftable>
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	ce0080e7          	jalr	-800(ra) # 80000ba8 <initlock>
}
    80004ed0:	60a2                	ld	ra,8(sp)
    80004ed2:	6402                	ld	s0,0(sp)
    80004ed4:	0141                	addi	sp,sp,16
    80004ed6:	8082                	ret

0000000080004ed8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004ed8:	1101                	addi	sp,sp,-32
    80004eda:	ec06                	sd	ra,24(sp)
    80004edc:	e822                	sd	s0,16(sp)
    80004ede:	e426                	sd	s1,8(sp)
    80004ee0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ee2:	00022517          	auipc	a0,0x22
    80004ee6:	17650513          	addi	a0,a0,374 # 80027058 <ftable>
    80004eea:	ffffc097          	auipc	ra,0xffffc
    80004eee:	d4e080e7          	jalr	-690(ra) # 80000c38 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ef2:	00022497          	auipc	s1,0x22
    80004ef6:	17e48493          	addi	s1,s1,382 # 80027070 <ftable+0x18>
    80004efa:	00023717          	auipc	a4,0x23
    80004efe:	11670713          	addi	a4,a4,278 # 80028010 <disk>
    if(f->ref == 0){
    80004f02:	40dc                	lw	a5,4(s1)
    80004f04:	cf99                	beqz	a5,80004f22 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004f06:	02848493          	addi	s1,s1,40
    80004f0a:	fee49ce3          	bne	s1,a4,80004f02 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004f0e:	00022517          	auipc	a0,0x22
    80004f12:	14a50513          	addi	a0,a0,330 # 80027058 <ftable>
    80004f16:	ffffc097          	auipc	ra,0xffffc
    80004f1a:	dd6080e7          	jalr	-554(ra) # 80000cec <release>
  return 0;
    80004f1e:	4481                	li	s1,0
    80004f20:	a819                	j	80004f36 <filealloc+0x5e>
      f->ref = 1;
    80004f22:	4785                	li	a5,1
    80004f24:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004f26:	00022517          	auipc	a0,0x22
    80004f2a:	13250513          	addi	a0,a0,306 # 80027058 <ftable>
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	dbe080e7          	jalr	-578(ra) # 80000cec <release>
}
    80004f36:	8526                	mv	a0,s1
    80004f38:	60e2                	ld	ra,24(sp)
    80004f3a:	6442                	ld	s0,16(sp)
    80004f3c:	64a2                	ld	s1,8(sp)
    80004f3e:	6105                	addi	sp,sp,32
    80004f40:	8082                	ret

0000000080004f42 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004f42:	1101                	addi	sp,sp,-32
    80004f44:	ec06                	sd	ra,24(sp)
    80004f46:	e822                	sd	s0,16(sp)
    80004f48:	e426                	sd	s1,8(sp)
    80004f4a:	1000                	addi	s0,sp,32
    80004f4c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004f4e:	00022517          	auipc	a0,0x22
    80004f52:	10a50513          	addi	a0,a0,266 # 80027058 <ftable>
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	ce2080e7          	jalr	-798(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004f5e:	40dc                	lw	a5,4(s1)
    80004f60:	02f05263          	blez	a5,80004f84 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004f64:	2785                	addiw	a5,a5,1
    80004f66:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004f68:	00022517          	auipc	a0,0x22
    80004f6c:	0f050513          	addi	a0,a0,240 # 80027058 <ftable>
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	d7c080e7          	jalr	-644(ra) # 80000cec <release>
  return f;
}
    80004f78:	8526                	mv	a0,s1
    80004f7a:	60e2                	ld	ra,24(sp)
    80004f7c:	6442                	ld	s0,16(sp)
    80004f7e:	64a2                	ld	s1,8(sp)
    80004f80:	6105                	addi	sp,sp,32
    80004f82:	8082                	ret
    panic("filedup");
    80004f84:	00003517          	auipc	a0,0x3
    80004f88:	62c50513          	addi	a0,a0,1580 # 800085b0 <etext+0x5b0>
    80004f8c:	ffffb097          	auipc	ra,0xffffb
    80004f90:	5d4080e7          	jalr	1492(ra) # 80000560 <panic>

0000000080004f94 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004f94:	7139                	addi	sp,sp,-64
    80004f96:	fc06                	sd	ra,56(sp)
    80004f98:	f822                	sd	s0,48(sp)
    80004f9a:	f426                	sd	s1,40(sp)
    80004f9c:	0080                	addi	s0,sp,64
    80004f9e:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004fa0:	00022517          	auipc	a0,0x22
    80004fa4:	0b850513          	addi	a0,a0,184 # 80027058 <ftable>
    80004fa8:	ffffc097          	auipc	ra,0xffffc
    80004fac:	c90080e7          	jalr	-880(ra) # 80000c38 <acquire>
  if(f->ref < 1)
    80004fb0:	40dc                	lw	a5,4(s1)
    80004fb2:	04f05c63          	blez	a5,8000500a <fileclose+0x76>
    panic("fileclose");
  if(--f->ref > 0){
    80004fb6:	37fd                	addiw	a5,a5,-1
    80004fb8:	0007871b          	sext.w	a4,a5
    80004fbc:	c0dc                	sw	a5,4(s1)
    80004fbe:	06e04263          	bgtz	a4,80005022 <fileclose+0x8e>
    80004fc2:	f04a                	sd	s2,32(sp)
    80004fc4:	ec4e                	sd	s3,24(sp)
    80004fc6:	e852                	sd	s4,16(sp)
    80004fc8:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004fca:	0004a903          	lw	s2,0(s1)
    80004fce:	0094ca83          	lbu	s5,9(s1)
    80004fd2:	0104ba03          	ld	s4,16(s1)
    80004fd6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004fda:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004fde:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004fe2:	00022517          	auipc	a0,0x22
    80004fe6:	07650513          	addi	a0,a0,118 # 80027058 <ftable>
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	d02080e7          	jalr	-766(ra) # 80000cec <release>

  if(ff.type == FD_PIPE){
    80004ff2:	4785                	li	a5,1
    80004ff4:	04f90463          	beq	s2,a5,8000503c <fileclose+0xa8>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ff8:	3979                	addiw	s2,s2,-2
    80004ffa:	4785                	li	a5,1
    80004ffc:	0527fb63          	bgeu	a5,s2,80005052 <fileclose+0xbe>
    80005000:	7902                	ld	s2,32(sp)
    80005002:	69e2                	ld	s3,24(sp)
    80005004:	6a42                	ld	s4,16(sp)
    80005006:	6aa2                	ld	s5,8(sp)
    80005008:	a02d                	j	80005032 <fileclose+0x9e>
    8000500a:	f04a                	sd	s2,32(sp)
    8000500c:	ec4e                	sd	s3,24(sp)
    8000500e:	e852                	sd	s4,16(sp)
    80005010:	e456                	sd	s5,8(sp)
    panic("fileclose");
    80005012:	00003517          	auipc	a0,0x3
    80005016:	5a650513          	addi	a0,a0,1446 # 800085b8 <etext+0x5b8>
    8000501a:	ffffb097          	auipc	ra,0xffffb
    8000501e:	546080e7          	jalr	1350(ra) # 80000560 <panic>
    release(&ftable.lock);
    80005022:	00022517          	auipc	a0,0x22
    80005026:	03650513          	addi	a0,a0,54 # 80027058 <ftable>
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	cc2080e7          	jalr	-830(ra) # 80000cec <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    80005032:	70e2                	ld	ra,56(sp)
    80005034:	7442                	ld	s0,48(sp)
    80005036:	74a2                	ld	s1,40(sp)
    80005038:	6121                	addi	sp,sp,64
    8000503a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000503c:	85d6                	mv	a1,s5
    8000503e:	8552                	mv	a0,s4
    80005040:	00000097          	auipc	ra,0x0
    80005044:	3a2080e7          	jalr	930(ra) # 800053e2 <pipeclose>
    80005048:	7902                	ld	s2,32(sp)
    8000504a:	69e2                	ld	s3,24(sp)
    8000504c:	6a42                	ld	s4,16(sp)
    8000504e:	6aa2                	ld	s5,8(sp)
    80005050:	b7cd                	j	80005032 <fileclose+0x9e>
    begin_op();
    80005052:	00000097          	auipc	ra,0x0
    80005056:	a78080e7          	jalr	-1416(ra) # 80004aca <begin_op>
    iput(ff.ip);
    8000505a:	854e                	mv	a0,s3
    8000505c:	fffff097          	auipc	ra,0xfffff
    80005060:	25e080e7          	jalr	606(ra) # 800042ba <iput>
    end_op();
    80005064:	00000097          	auipc	ra,0x0
    80005068:	ae0080e7          	jalr	-1312(ra) # 80004b44 <end_op>
    8000506c:	7902                	ld	s2,32(sp)
    8000506e:	69e2                	ld	s3,24(sp)
    80005070:	6a42                	ld	s4,16(sp)
    80005072:	6aa2                	ld	s5,8(sp)
    80005074:	bf7d                	j	80005032 <fileclose+0x9e>

0000000080005076 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005076:	715d                	addi	sp,sp,-80
    80005078:	e486                	sd	ra,72(sp)
    8000507a:	e0a2                	sd	s0,64(sp)
    8000507c:	fc26                	sd	s1,56(sp)
    8000507e:	f44e                	sd	s3,40(sp)
    80005080:	0880                	addi	s0,sp,80
    80005082:	84aa                	mv	s1,a0
    80005084:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005086:	ffffd097          	auipc	ra,0xffffd
    8000508a:	cae080e7          	jalr	-850(ra) # 80001d34 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000508e:	409c                	lw	a5,0(s1)
    80005090:	37f9                	addiw	a5,a5,-2
    80005092:	4705                	li	a4,1
    80005094:	04f76863          	bltu	a4,a5,800050e4 <filestat+0x6e>
    80005098:	f84a                	sd	s2,48(sp)
    8000509a:	892a                	mv	s2,a0
    ilock(f->ip);
    8000509c:	6c88                	ld	a0,24(s1)
    8000509e:	fffff097          	auipc	ra,0xfffff
    800050a2:	05e080e7          	jalr	94(ra) # 800040fc <ilock>
    stati(f->ip, &st);
    800050a6:	fb840593          	addi	a1,s0,-72
    800050aa:	6c88                	ld	a0,24(s1)
    800050ac:	fffff097          	auipc	ra,0xfffff
    800050b0:	2de080e7          	jalr	734(ra) # 8000438a <stati>
    iunlock(f->ip);
    800050b4:	6c88                	ld	a0,24(s1)
    800050b6:	fffff097          	auipc	ra,0xfffff
    800050ba:	10c080e7          	jalr	268(ra) # 800041c2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800050be:	46e1                	li	a3,24
    800050c0:	fb840613          	addi	a2,s0,-72
    800050c4:	85ce                	mv	a1,s3
    800050c6:	05093503          	ld	a0,80(s2)
    800050ca:	ffffc097          	auipc	ra,0xffffc
    800050ce:	618080e7          	jalr	1560(ra) # 800016e2 <copyout>
    800050d2:	41f5551b          	sraiw	a0,a0,0x1f
    800050d6:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    800050d8:	60a6                	ld	ra,72(sp)
    800050da:	6406                	ld	s0,64(sp)
    800050dc:	74e2                	ld	s1,56(sp)
    800050de:	79a2                	ld	s3,40(sp)
    800050e0:	6161                	addi	sp,sp,80
    800050e2:	8082                	ret
  return -1;
    800050e4:	557d                	li	a0,-1
    800050e6:	bfcd                	j	800050d8 <filestat+0x62>

00000000800050e8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800050e8:	7179                	addi	sp,sp,-48
    800050ea:	f406                	sd	ra,40(sp)
    800050ec:	f022                	sd	s0,32(sp)
    800050ee:	e84a                	sd	s2,16(sp)
    800050f0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800050f2:	00854783          	lbu	a5,8(a0)
    800050f6:	cbc5                	beqz	a5,800051a6 <fileread+0xbe>
    800050f8:	ec26                	sd	s1,24(sp)
    800050fa:	e44e                	sd	s3,8(sp)
    800050fc:	84aa                	mv	s1,a0
    800050fe:	89ae                	mv	s3,a1
    80005100:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005102:	411c                	lw	a5,0(a0)
    80005104:	4705                	li	a4,1
    80005106:	04e78963          	beq	a5,a4,80005158 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000510a:	470d                	li	a4,3
    8000510c:	04e78f63          	beq	a5,a4,8000516a <fileread+0x82>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005110:	4709                	li	a4,2
    80005112:	08e79263          	bne	a5,a4,80005196 <fileread+0xae>
    ilock(f->ip);
    80005116:	6d08                	ld	a0,24(a0)
    80005118:	fffff097          	auipc	ra,0xfffff
    8000511c:	fe4080e7          	jalr	-28(ra) # 800040fc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005120:	874a                	mv	a4,s2
    80005122:	5094                	lw	a3,32(s1)
    80005124:	864e                	mv	a2,s3
    80005126:	4585                	li	a1,1
    80005128:	6c88                	ld	a0,24(s1)
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	28a080e7          	jalr	650(ra) # 800043b4 <readi>
    80005132:	892a                	mv	s2,a0
    80005134:	00a05563          	blez	a0,8000513e <fileread+0x56>
      f->off += r;
    80005138:	509c                	lw	a5,32(s1)
    8000513a:	9fa9                	addw	a5,a5,a0
    8000513c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000513e:	6c88                	ld	a0,24(s1)
    80005140:	fffff097          	auipc	ra,0xfffff
    80005144:	082080e7          	jalr	130(ra) # 800041c2 <iunlock>
    80005148:	64e2                	ld	s1,24(sp)
    8000514a:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    8000514c:	854a                	mv	a0,s2
    8000514e:	70a2                	ld	ra,40(sp)
    80005150:	7402                	ld	s0,32(sp)
    80005152:	6942                	ld	s2,16(sp)
    80005154:	6145                	addi	sp,sp,48
    80005156:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005158:	6908                	ld	a0,16(a0)
    8000515a:	00000097          	auipc	ra,0x0
    8000515e:	400080e7          	jalr	1024(ra) # 8000555a <piperead>
    80005162:	892a                	mv	s2,a0
    80005164:	64e2                	ld	s1,24(sp)
    80005166:	69a2                	ld	s3,8(sp)
    80005168:	b7d5                	j	8000514c <fileread+0x64>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000516a:	02451783          	lh	a5,36(a0)
    8000516e:	03079693          	slli	a3,a5,0x30
    80005172:	92c1                	srli	a3,a3,0x30
    80005174:	4725                	li	a4,9
    80005176:	02d76a63          	bltu	a4,a3,800051aa <fileread+0xc2>
    8000517a:	0792                	slli	a5,a5,0x4
    8000517c:	00022717          	auipc	a4,0x22
    80005180:	e3c70713          	addi	a4,a4,-452 # 80026fb8 <devsw>
    80005184:	97ba                	add	a5,a5,a4
    80005186:	639c                	ld	a5,0(a5)
    80005188:	c78d                	beqz	a5,800051b2 <fileread+0xca>
    r = devsw[f->major].read(1, addr, n);
    8000518a:	4505                	li	a0,1
    8000518c:	9782                	jalr	a5
    8000518e:	892a                	mv	s2,a0
    80005190:	64e2                	ld	s1,24(sp)
    80005192:	69a2                	ld	s3,8(sp)
    80005194:	bf65                	j	8000514c <fileread+0x64>
    panic("fileread");
    80005196:	00003517          	auipc	a0,0x3
    8000519a:	43250513          	addi	a0,a0,1074 # 800085c8 <etext+0x5c8>
    8000519e:	ffffb097          	auipc	ra,0xffffb
    800051a2:	3c2080e7          	jalr	962(ra) # 80000560 <panic>
    return -1;
    800051a6:	597d                	li	s2,-1
    800051a8:	b755                	j	8000514c <fileread+0x64>
      return -1;
    800051aa:	597d                	li	s2,-1
    800051ac:	64e2                	ld	s1,24(sp)
    800051ae:	69a2                	ld	s3,8(sp)
    800051b0:	bf71                	j	8000514c <fileread+0x64>
    800051b2:	597d                	li	s2,-1
    800051b4:	64e2                	ld	s1,24(sp)
    800051b6:	69a2                	ld	s3,8(sp)
    800051b8:	bf51                	j	8000514c <fileread+0x64>

00000000800051ba <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800051ba:	00954783          	lbu	a5,9(a0)
    800051be:	12078963          	beqz	a5,800052f0 <filewrite+0x136>
{
    800051c2:	715d                	addi	sp,sp,-80
    800051c4:	e486                	sd	ra,72(sp)
    800051c6:	e0a2                	sd	s0,64(sp)
    800051c8:	f84a                	sd	s2,48(sp)
    800051ca:	f052                	sd	s4,32(sp)
    800051cc:	e85a                	sd	s6,16(sp)
    800051ce:	0880                	addi	s0,sp,80
    800051d0:	892a                	mv	s2,a0
    800051d2:	8b2e                	mv	s6,a1
    800051d4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800051d6:	411c                	lw	a5,0(a0)
    800051d8:	4705                	li	a4,1
    800051da:	02e78763          	beq	a5,a4,80005208 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800051de:	470d                	li	a4,3
    800051e0:	02e78a63          	beq	a5,a4,80005214 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800051e4:	4709                	li	a4,2
    800051e6:	0ee79863          	bne	a5,a4,800052d6 <filewrite+0x11c>
    800051ea:	f44e                	sd	s3,40(sp)
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800051ec:	0cc05463          	blez	a2,800052b4 <filewrite+0xfa>
    800051f0:	fc26                	sd	s1,56(sp)
    800051f2:	ec56                	sd	s5,24(sp)
    800051f4:	e45e                	sd	s7,8(sp)
    800051f6:	e062                	sd	s8,0(sp)
    int i = 0;
    800051f8:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    800051fa:	6b85                	lui	s7,0x1
    800051fc:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80005200:	6c05                	lui	s8,0x1
    80005202:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005206:	a851                	j	8000529a <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80005208:	6908                	ld	a0,16(a0)
    8000520a:	00000097          	auipc	ra,0x0
    8000520e:	248080e7          	jalr	584(ra) # 80005452 <pipewrite>
    80005212:	a85d                	j	800052c8 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005214:	02451783          	lh	a5,36(a0)
    80005218:	03079693          	slli	a3,a5,0x30
    8000521c:	92c1                	srli	a3,a3,0x30
    8000521e:	4725                	li	a4,9
    80005220:	0cd76a63          	bltu	a4,a3,800052f4 <filewrite+0x13a>
    80005224:	0792                	slli	a5,a5,0x4
    80005226:	00022717          	auipc	a4,0x22
    8000522a:	d9270713          	addi	a4,a4,-622 # 80026fb8 <devsw>
    8000522e:	97ba                	add	a5,a5,a4
    80005230:	679c                	ld	a5,8(a5)
    80005232:	c3f9                	beqz	a5,800052f8 <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    80005234:	4505                	li	a0,1
    80005236:	9782                	jalr	a5
    80005238:	a841                	j	800052c8 <filewrite+0x10e>
      if(n1 > max)
    8000523a:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    8000523e:	00000097          	auipc	ra,0x0
    80005242:	88c080e7          	jalr	-1908(ra) # 80004aca <begin_op>
      ilock(f->ip);
    80005246:	01893503          	ld	a0,24(s2)
    8000524a:	fffff097          	auipc	ra,0xfffff
    8000524e:	eb2080e7          	jalr	-334(ra) # 800040fc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005252:	8756                	mv	a4,s5
    80005254:	02092683          	lw	a3,32(s2)
    80005258:	01698633          	add	a2,s3,s6
    8000525c:	4585                	li	a1,1
    8000525e:	01893503          	ld	a0,24(s2)
    80005262:	fffff097          	auipc	ra,0xfffff
    80005266:	262080e7          	jalr	610(ra) # 800044c4 <writei>
    8000526a:	84aa                	mv	s1,a0
    8000526c:	00a05763          	blez	a0,8000527a <filewrite+0xc0>
        f->off += r;
    80005270:	02092783          	lw	a5,32(s2)
    80005274:	9fa9                	addw	a5,a5,a0
    80005276:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000527a:	01893503          	ld	a0,24(s2)
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	f44080e7          	jalr	-188(ra) # 800041c2 <iunlock>
      end_op();
    80005286:	00000097          	auipc	ra,0x0
    8000528a:	8be080e7          	jalr	-1858(ra) # 80004b44 <end_op>

      if(r != n1){
    8000528e:	029a9563          	bne	s5,s1,800052b8 <filewrite+0xfe>
        // error from writei
        break;
      }
      i += r;
    80005292:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005296:	0149da63          	bge	s3,s4,800052aa <filewrite+0xf0>
      int n1 = n - i;
    8000529a:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    8000529e:	0004879b          	sext.w	a5,s1
    800052a2:	f8fbdce3          	bge	s7,a5,8000523a <filewrite+0x80>
    800052a6:	84e2                	mv	s1,s8
    800052a8:	bf49                	j	8000523a <filewrite+0x80>
    800052aa:	74e2                	ld	s1,56(sp)
    800052ac:	6ae2                	ld	s5,24(sp)
    800052ae:	6ba2                	ld	s7,8(sp)
    800052b0:	6c02                	ld	s8,0(sp)
    800052b2:	a039                	j	800052c0 <filewrite+0x106>
    int i = 0;
    800052b4:	4981                	li	s3,0
    800052b6:	a029                	j	800052c0 <filewrite+0x106>
    800052b8:	74e2                	ld	s1,56(sp)
    800052ba:	6ae2                	ld	s5,24(sp)
    800052bc:	6ba2                	ld	s7,8(sp)
    800052be:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    800052c0:	033a1e63          	bne	s4,s3,800052fc <filewrite+0x142>
    800052c4:	8552                	mv	a0,s4
    800052c6:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    800052c8:	60a6                	ld	ra,72(sp)
    800052ca:	6406                	ld	s0,64(sp)
    800052cc:	7942                	ld	s2,48(sp)
    800052ce:	7a02                	ld	s4,32(sp)
    800052d0:	6b42                	ld	s6,16(sp)
    800052d2:	6161                	addi	sp,sp,80
    800052d4:	8082                	ret
    800052d6:	fc26                	sd	s1,56(sp)
    800052d8:	f44e                	sd	s3,40(sp)
    800052da:	ec56                	sd	s5,24(sp)
    800052dc:	e45e                	sd	s7,8(sp)
    800052de:	e062                	sd	s8,0(sp)
    panic("filewrite");
    800052e0:	00003517          	auipc	a0,0x3
    800052e4:	2f850513          	addi	a0,a0,760 # 800085d8 <etext+0x5d8>
    800052e8:	ffffb097          	auipc	ra,0xffffb
    800052ec:	278080e7          	jalr	632(ra) # 80000560 <panic>
    return -1;
    800052f0:	557d                	li	a0,-1
}
    800052f2:	8082                	ret
      return -1;
    800052f4:	557d                	li	a0,-1
    800052f6:	bfc9                	j	800052c8 <filewrite+0x10e>
    800052f8:	557d                	li	a0,-1
    800052fa:	b7f9                	j	800052c8 <filewrite+0x10e>
    ret = (i == n ? n : -1);
    800052fc:	557d                	li	a0,-1
    800052fe:	79a2                	ld	s3,40(sp)
    80005300:	b7e1                	j	800052c8 <filewrite+0x10e>

0000000080005302 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005302:	7179                	addi	sp,sp,-48
    80005304:	f406                	sd	ra,40(sp)
    80005306:	f022                	sd	s0,32(sp)
    80005308:	ec26                	sd	s1,24(sp)
    8000530a:	e052                	sd	s4,0(sp)
    8000530c:	1800                	addi	s0,sp,48
    8000530e:	84aa                	mv	s1,a0
    80005310:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005312:	0005b023          	sd	zero,0(a1)
    80005316:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	bbe080e7          	jalr	-1090(ra) # 80004ed8 <filealloc>
    80005322:	e088                	sd	a0,0(s1)
    80005324:	cd49                	beqz	a0,800053be <pipealloc+0xbc>
    80005326:	00000097          	auipc	ra,0x0
    8000532a:	bb2080e7          	jalr	-1102(ra) # 80004ed8 <filealloc>
    8000532e:	00aa3023          	sd	a0,0(s4)
    80005332:	c141                	beqz	a0,800053b2 <pipealloc+0xb0>
    80005334:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	812080e7          	jalr	-2030(ra) # 80000b48 <kalloc>
    8000533e:	892a                	mv	s2,a0
    80005340:	c13d                	beqz	a0,800053a6 <pipealloc+0xa4>
    80005342:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80005344:	4985                	li	s3,1
    80005346:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000534a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000534e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80005352:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005356:	00003597          	auipc	a1,0x3
    8000535a:	29258593          	addi	a1,a1,658 # 800085e8 <etext+0x5e8>
    8000535e:	ffffc097          	auipc	ra,0xffffc
    80005362:	84a080e7          	jalr	-1974(ra) # 80000ba8 <initlock>
  (*f0)->type = FD_PIPE;
    80005366:	609c                	ld	a5,0(s1)
    80005368:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000536c:	609c                	ld	a5,0(s1)
    8000536e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005372:	609c                	ld	a5,0(s1)
    80005374:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005378:	609c                	ld	a5,0(s1)
    8000537a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000537e:	000a3783          	ld	a5,0(s4)
    80005382:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005386:	000a3783          	ld	a5,0(s4)
    8000538a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000538e:	000a3783          	ld	a5,0(s4)
    80005392:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005396:	000a3783          	ld	a5,0(s4)
    8000539a:	0127b823          	sd	s2,16(a5)
  return 0;
    8000539e:	4501                	li	a0,0
    800053a0:	6942                	ld	s2,16(sp)
    800053a2:	69a2                	ld	s3,8(sp)
    800053a4:	a03d                	j	800053d2 <pipealloc+0xd0>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800053a6:	6088                	ld	a0,0(s1)
    800053a8:	c119                	beqz	a0,800053ae <pipealloc+0xac>
    800053aa:	6942                	ld	s2,16(sp)
    800053ac:	a029                	j	800053b6 <pipealloc+0xb4>
    800053ae:	6942                	ld	s2,16(sp)
    800053b0:	a039                	j	800053be <pipealloc+0xbc>
    800053b2:	6088                	ld	a0,0(s1)
    800053b4:	c50d                	beqz	a0,800053de <pipealloc+0xdc>
    fileclose(*f0);
    800053b6:	00000097          	auipc	ra,0x0
    800053ba:	bde080e7          	jalr	-1058(ra) # 80004f94 <fileclose>
  if(*f1)
    800053be:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800053c2:	557d                	li	a0,-1
  if(*f1)
    800053c4:	c799                	beqz	a5,800053d2 <pipealloc+0xd0>
    fileclose(*f1);
    800053c6:	853e                	mv	a0,a5
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	bcc080e7          	jalr	-1076(ra) # 80004f94 <fileclose>
  return -1;
    800053d0:	557d                	li	a0,-1
}
    800053d2:	70a2                	ld	ra,40(sp)
    800053d4:	7402                	ld	s0,32(sp)
    800053d6:	64e2                	ld	s1,24(sp)
    800053d8:	6a02                	ld	s4,0(sp)
    800053da:	6145                	addi	sp,sp,48
    800053dc:	8082                	ret
  return -1;
    800053de:	557d                	li	a0,-1
    800053e0:	bfcd                	j	800053d2 <pipealloc+0xd0>

00000000800053e2 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800053e2:	1101                	addi	sp,sp,-32
    800053e4:	ec06                	sd	ra,24(sp)
    800053e6:	e822                	sd	s0,16(sp)
    800053e8:	e426                	sd	s1,8(sp)
    800053ea:	e04a                	sd	s2,0(sp)
    800053ec:	1000                	addi	s0,sp,32
    800053ee:	84aa                	mv	s1,a0
    800053f0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800053f2:	ffffc097          	auipc	ra,0xffffc
    800053f6:	846080e7          	jalr	-1978(ra) # 80000c38 <acquire>
  if(writable){
    800053fa:	02090d63          	beqz	s2,80005434 <pipeclose+0x52>
    pi->writeopen = 0;
    800053fe:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80005402:	21848513          	addi	a0,s1,536
    80005406:	ffffd097          	auipc	ra,0xffffd
    8000540a:	1ce080e7          	jalr	462(ra) # 800025d4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000540e:	2204b783          	ld	a5,544(s1)
    80005412:	eb95                	bnez	a5,80005446 <pipeclose+0x64>
    release(&pi->lock);
    80005414:	8526                	mv	a0,s1
    80005416:	ffffc097          	auipc	ra,0xffffc
    8000541a:	8d6080e7          	jalr	-1834(ra) # 80000cec <release>
    kfree((char*)pi);
    8000541e:	8526                	mv	a0,s1
    80005420:	ffffb097          	auipc	ra,0xffffb
    80005424:	62a080e7          	jalr	1578(ra) # 80000a4a <kfree>
  } else
    release(&pi->lock);
}
    80005428:	60e2                	ld	ra,24(sp)
    8000542a:	6442                	ld	s0,16(sp)
    8000542c:	64a2                	ld	s1,8(sp)
    8000542e:	6902                	ld	s2,0(sp)
    80005430:	6105                	addi	sp,sp,32
    80005432:	8082                	ret
    pi->readopen = 0;
    80005434:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005438:	21c48513          	addi	a0,s1,540
    8000543c:	ffffd097          	auipc	ra,0xffffd
    80005440:	198080e7          	jalr	408(ra) # 800025d4 <wakeup>
    80005444:	b7e9                	j	8000540e <pipeclose+0x2c>
    release(&pi->lock);
    80005446:	8526                	mv	a0,s1
    80005448:	ffffc097          	auipc	ra,0xffffc
    8000544c:	8a4080e7          	jalr	-1884(ra) # 80000cec <release>
}
    80005450:	bfe1                	j	80005428 <pipeclose+0x46>

0000000080005452 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005452:	711d                	addi	sp,sp,-96
    80005454:	ec86                	sd	ra,88(sp)
    80005456:	e8a2                	sd	s0,80(sp)
    80005458:	e4a6                	sd	s1,72(sp)
    8000545a:	e0ca                	sd	s2,64(sp)
    8000545c:	fc4e                	sd	s3,56(sp)
    8000545e:	f852                	sd	s4,48(sp)
    80005460:	f456                	sd	s5,40(sp)
    80005462:	1080                	addi	s0,sp,96
    80005464:	84aa                	mv	s1,a0
    80005466:	8aae                	mv	s5,a1
    80005468:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    8000546a:	ffffd097          	auipc	ra,0xffffd
    8000546e:	8ca080e7          	jalr	-1846(ra) # 80001d34 <myproc>
    80005472:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005474:	8526                	mv	a0,s1
    80005476:	ffffb097          	auipc	ra,0xffffb
    8000547a:	7c2080e7          	jalr	1986(ra) # 80000c38 <acquire>
  while(i < n){
    8000547e:	0d405863          	blez	s4,8000554e <pipewrite+0xfc>
    80005482:	f05a                	sd	s6,32(sp)
    80005484:	ec5e                	sd	s7,24(sp)
    80005486:	e862                	sd	s8,16(sp)
  int i = 0;
    80005488:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000548a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000548c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005490:	21c48b93          	addi	s7,s1,540
    80005494:	a089                	j	800054d6 <pipewrite+0x84>
      release(&pi->lock);
    80005496:	8526                	mv	a0,s1
    80005498:	ffffc097          	auipc	ra,0xffffc
    8000549c:	854080e7          	jalr	-1964(ra) # 80000cec <release>
      return -1;
    800054a0:	597d                	li	s2,-1
    800054a2:	7b02                	ld	s6,32(sp)
    800054a4:	6be2                	ld	s7,24(sp)
    800054a6:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800054a8:	854a                	mv	a0,s2
    800054aa:	60e6                	ld	ra,88(sp)
    800054ac:	6446                	ld	s0,80(sp)
    800054ae:	64a6                	ld	s1,72(sp)
    800054b0:	6906                	ld	s2,64(sp)
    800054b2:	79e2                	ld	s3,56(sp)
    800054b4:	7a42                	ld	s4,48(sp)
    800054b6:	7aa2                	ld	s5,40(sp)
    800054b8:	6125                	addi	sp,sp,96
    800054ba:	8082                	ret
      wakeup(&pi->nread);
    800054bc:	8562                	mv	a0,s8
    800054be:	ffffd097          	auipc	ra,0xffffd
    800054c2:	116080e7          	jalr	278(ra) # 800025d4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800054c6:	85a6                	mv	a1,s1
    800054c8:	855e                	mv	a0,s7
    800054ca:	ffffd097          	auipc	ra,0xffffd
    800054ce:	08c080e7          	jalr	140(ra) # 80002556 <sleep>
  while(i < n){
    800054d2:	05495f63          	bge	s2,s4,80005530 <pipewrite+0xde>
    if(pi->readopen == 0 || killed(pr)){
    800054d6:	2204a783          	lw	a5,544(s1)
    800054da:	dfd5                	beqz	a5,80005496 <pipewrite+0x44>
    800054dc:	854e                	mv	a0,s3
    800054de:	ffffd097          	auipc	ra,0xffffd
    800054e2:	35c080e7          	jalr	860(ra) # 8000283a <killed>
    800054e6:	f945                	bnez	a0,80005496 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800054e8:	2184a783          	lw	a5,536(s1)
    800054ec:	21c4a703          	lw	a4,540(s1)
    800054f0:	2007879b          	addiw	a5,a5,512
    800054f4:	fcf704e3          	beq	a4,a5,800054bc <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800054f8:	4685                	li	a3,1
    800054fa:	01590633          	add	a2,s2,s5
    800054fe:	faf40593          	addi	a1,s0,-81
    80005502:	0509b503          	ld	a0,80(s3)
    80005506:	ffffc097          	auipc	ra,0xffffc
    8000550a:	268080e7          	jalr	616(ra) # 8000176e <copyin>
    8000550e:	05650263          	beq	a0,s6,80005552 <pipewrite+0x100>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005512:	21c4a783          	lw	a5,540(s1)
    80005516:	0017871b          	addiw	a4,a5,1
    8000551a:	20e4ae23          	sw	a4,540(s1)
    8000551e:	1ff7f793          	andi	a5,a5,511
    80005522:	97a6                	add	a5,a5,s1
    80005524:	faf44703          	lbu	a4,-81(s0)
    80005528:	00e78c23          	sb	a4,24(a5)
      i++;
    8000552c:	2905                	addiw	s2,s2,1
    8000552e:	b755                	j	800054d2 <pipewrite+0x80>
    80005530:	7b02                	ld	s6,32(sp)
    80005532:	6be2                	ld	s7,24(sp)
    80005534:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80005536:	21848513          	addi	a0,s1,536
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	09a080e7          	jalr	154(ra) # 800025d4 <wakeup>
  release(&pi->lock);
    80005542:	8526                	mv	a0,s1
    80005544:	ffffb097          	auipc	ra,0xffffb
    80005548:	7a8080e7          	jalr	1960(ra) # 80000cec <release>
  return i;
    8000554c:	bfb1                	j	800054a8 <pipewrite+0x56>
  int i = 0;
    8000554e:	4901                	li	s2,0
    80005550:	b7dd                	j	80005536 <pipewrite+0xe4>
    80005552:	7b02                	ld	s6,32(sp)
    80005554:	6be2                	ld	s7,24(sp)
    80005556:	6c42                	ld	s8,16(sp)
    80005558:	bff9                	j	80005536 <pipewrite+0xe4>

000000008000555a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000555a:	715d                	addi	sp,sp,-80
    8000555c:	e486                	sd	ra,72(sp)
    8000555e:	e0a2                	sd	s0,64(sp)
    80005560:	fc26                	sd	s1,56(sp)
    80005562:	f84a                	sd	s2,48(sp)
    80005564:	f44e                	sd	s3,40(sp)
    80005566:	f052                	sd	s4,32(sp)
    80005568:	ec56                	sd	s5,24(sp)
    8000556a:	0880                	addi	s0,sp,80
    8000556c:	84aa                	mv	s1,a0
    8000556e:	892e                	mv	s2,a1
    80005570:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005572:	ffffc097          	auipc	ra,0xffffc
    80005576:	7c2080e7          	jalr	1986(ra) # 80001d34 <myproc>
    8000557a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffb097          	auipc	ra,0xffffb
    80005582:	6ba080e7          	jalr	1722(ra) # 80000c38 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005586:	2184a703          	lw	a4,536(s1)
    8000558a:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000558e:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005592:	02f71963          	bne	a4,a5,800055c4 <piperead+0x6a>
    80005596:	2244a783          	lw	a5,548(s1)
    8000559a:	cf95                	beqz	a5,800055d6 <piperead+0x7c>
    if(killed(pr)){
    8000559c:	8552                	mv	a0,s4
    8000559e:	ffffd097          	auipc	ra,0xffffd
    800055a2:	29c080e7          	jalr	668(ra) # 8000283a <killed>
    800055a6:	e10d                	bnez	a0,800055c8 <piperead+0x6e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800055a8:	85a6                	mv	a1,s1
    800055aa:	854e                	mv	a0,s3
    800055ac:	ffffd097          	auipc	ra,0xffffd
    800055b0:	faa080e7          	jalr	-86(ra) # 80002556 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800055b4:	2184a703          	lw	a4,536(s1)
    800055b8:	21c4a783          	lw	a5,540(s1)
    800055bc:	fcf70de3          	beq	a4,a5,80005596 <piperead+0x3c>
    800055c0:	e85a                	sd	s6,16(sp)
    800055c2:	a819                	j	800055d8 <piperead+0x7e>
    800055c4:	e85a                	sd	s6,16(sp)
    800055c6:	a809                	j	800055d8 <piperead+0x7e>
      release(&pi->lock);
    800055c8:	8526                	mv	a0,s1
    800055ca:	ffffb097          	auipc	ra,0xffffb
    800055ce:	722080e7          	jalr	1826(ra) # 80000cec <release>
      return -1;
    800055d2:	59fd                	li	s3,-1
    800055d4:	a0a5                	j	8000563c <piperead+0xe2>
    800055d6:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055d8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800055da:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800055dc:	05505463          	blez	s5,80005624 <piperead+0xca>
    if(pi->nread == pi->nwrite)
    800055e0:	2184a783          	lw	a5,536(s1)
    800055e4:	21c4a703          	lw	a4,540(s1)
    800055e8:	02f70e63          	beq	a4,a5,80005624 <piperead+0xca>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800055ec:	0017871b          	addiw	a4,a5,1
    800055f0:	20e4ac23          	sw	a4,536(s1)
    800055f4:	1ff7f793          	andi	a5,a5,511
    800055f8:	97a6                	add	a5,a5,s1
    800055fa:	0187c783          	lbu	a5,24(a5)
    800055fe:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005602:	4685                	li	a3,1
    80005604:	fbf40613          	addi	a2,s0,-65
    80005608:	85ca                	mv	a1,s2
    8000560a:	050a3503          	ld	a0,80(s4)
    8000560e:	ffffc097          	auipc	ra,0xffffc
    80005612:	0d4080e7          	jalr	212(ra) # 800016e2 <copyout>
    80005616:	01650763          	beq	a0,s6,80005624 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000561a:	2985                	addiw	s3,s3,1
    8000561c:	0905                	addi	s2,s2,1
    8000561e:	fd3a91e3          	bne	s5,s3,800055e0 <piperead+0x86>
    80005622:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005624:	21c48513          	addi	a0,s1,540
    80005628:	ffffd097          	auipc	ra,0xffffd
    8000562c:	fac080e7          	jalr	-84(ra) # 800025d4 <wakeup>
  release(&pi->lock);
    80005630:	8526                	mv	a0,s1
    80005632:	ffffb097          	auipc	ra,0xffffb
    80005636:	6ba080e7          	jalr	1722(ra) # 80000cec <release>
    8000563a:	6b42                	ld	s6,16(sp)
  return i;
}
    8000563c:	854e                	mv	a0,s3
    8000563e:	60a6                	ld	ra,72(sp)
    80005640:	6406                	ld	s0,64(sp)
    80005642:	74e2                	ld	s1,56(sp)
    80005644:	7942                	ld	s2,48(sp)
    80005646:	79a2                	ld	s3,40(sp)
    80005648:	7a02                	ld	s4,32(sp)
    8000564a:	6ae2                	ld	s5,24(sp)
    8000564c:	6161                	addi	sp,sp,80
    8000564e:	8082                	ret

0000000080005650 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005650:	1141                	addi	sp,sp,-16
    80005652:	e422                	sd	s0,8(sp)
    80005654:	0800                	addi	s0,sp,16
    80005656:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005658:	8905                	andi	a0,a0,1
    8000565a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000565c:	8b89                	andi	a5,a5,2
    8000565e:	c399                	beqz	a5,80005664 <flags2perm+0x14>
      perm |= PTE_W;
    80005660:	00456513          	ori	a0,a0,4
    return perm;
}
    80005664:	6422                	ld	s0,8(sp)
    80005666:	0141                	addi	sp,sp,16
    80005668:	8082                	ret

000000008000566a <exec>:

int
exec(char *path, char **argv)
{
    8000566a:	df010113          	addi	sp,sp,-528
    8000566e:	20113423          	sd	ra,520(sp)
    80005672:	20813023          	sd	s0,512(sp)
    80005676:	ffa6                	sd	s1,504(sp)
    80005678:	fbca                	sd	s2,496(sp)
    8000567a:	0c00                	addi	s0,sp,528
    8000567c:	892a                	mv	s2,a0
    8000567e:	dea43c23          	sd	a0,-520(s0)
    80005682:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005686:	ffffc097          	auipc	ra,0xffffc
    8000568a:	6ae080e7          	jalr	1710(ra) # 80001d34 <myproc>
    8000568e:	84aa                	mv	s1,a0

  begin_op();
    80005690:	fffff097          	auipc	ra,0xfffff
    80005694:	43a080e7          	jalr	1082(ra) # 80004aca <begin_op>

  if((ip = namei(path)) == 0){
    80005698:	854a                	mv	a0,s2
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	230080e7          	jalr	560(ra) # 800048ca <namei>
    800056a2:	c135                	beqz	a0,80005706 <exec+0x9c>
    800056a4:	f3d2                	sd	s4,480(sp)
    800056a6:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	a54080e7          	jalr	-1452(ra) # 800040fc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800056b0:	04000713          	li	a4,64
    800056b4:	4681                	li	a3,0
    800056b6:	e5040613          	addi	a2,s0,-432
    800056ba:	4581                	li	a1,0
    800056bc:	8552                	mv	a0,s4
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	cf6080e7          	jalr	-778(ra) # 800043b4 <readi>
    800056c6:	04000793          	li	a5,64
    800056ca:	00f51a63          	bne	a0,a5,800056de <exec+0x74>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800056ce:	e5042703          	lw	a4,-432(s0)
    800056d2:	464c47b7          	lui	a5,0x464c4
    800056d6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800056da:	02f70c63          	beq	a4,a5,80005712 <exec+0xa8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800056de:	8552                	mv	a0,s4
    800056e0:	fffff097          	auipc	ra,0xfffff
    800056e4:	c82080e7          	jalr	-894(ra) # 80004362 <iunlockput>
    end_op();
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	45c080e7          	jalr	1116(ra) # 80004b44 <end_op>
  }
  return -1;
    800056f0:	557d                	li	a0,-1
    800056f2:	7a1e                	ld	s4,480(sp)
}
    800056f4:	20813083          	ld	ra,520(sp)
    800056f8:	20013403          	ld	s0,512(sp)
    800056fc:	74fe                	ld	s1,504(sp)
    800056fe:	795e                	ld	s2,496(sp)
    80005700:	21010113          	addi	sp,sp,528
    80005704:	8082                	ret
    end_op();
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	43e080e7          	jalr	1086(ra) # 80004b44 <end_op>
    return -1;
    8000570e:	557d                	li	a0,-1
    80005710:	b7d5                	j	800056f4 <exec+0x8a>
    80005712:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    80005714:	8526                	mv	a0,s1
    80005716:	ffffc097          	auipc	ra,0xffffc
    8000571a:	6e2080e7          	jalr	1762(ra) # 80001df8 <proc_pagetable>
    8000571e:	8b2a                	mv	s6,a0
    80005720:	30050f63          	beqz	a0,80005a3e <exec+0x3d4>
    80005724:	f7ce                	sd	s3,488(sp)
    80005726:	efd6                	sd	s5,472(sp)
    80005728:	e7de                	sd	s7,456(sp)
    8000572a:	e3e2                	sd	s8,448(sp)
    8000572c:	ff66                	sd	s9,440(sp)
    8000572e:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005730:	e7042d03          	lw	s10,-400(s0)
    80005734:	e8845783          	lhu	a5,-376(s0)
    80005738:	14078d63          	beqz	a5,80005892 <exec+0x228>
    8000573c:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000573e:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005740:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005742:	6c85                	lui	s9,0x1
    80005744:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005748:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000574c:	6a85                	lui	s5,0x1
    8000574e:	a0b5                	j	800057ba <exec+0x150>
      panic("loadseg: address should exist");
    80005750:	00003517          	auipc	a0,0x3
    80005754:	ea050513          	addi	a0,a0,-352 # 800085f0 <etext+0x5f0>
    80005758:	ffffb097          	auipc	ra,0xffffb
    8000575c:	e08080e7          	jalr	-504(ra) # 80000560 <panic>
    if(sz - i < PGSIZE)
    80005760:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005762:	8726                	mv	a4,s1
    80005764:	012c06bb          	addw	a3,s8,s2
    80005768:	4581                	li	a1,0
    8000576a:	8552                	mv	a0,s4
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	c48080e7          	jalr	-952(ra) # 800043b4 <readi>
    80005774:	2501                	sext.w	a0,a0
    80005776:	28a49863          	bne	s1,a0,80005a06 <exec+0x39c>
  for(i = 0; i < sz; i += PGSIZE){
    8000577a:	012a893b          	addw	s2,s5,s2
    8000577e:	03397563          	bgeu	s2,s3,800057a8 <exec+0x13e>
    pa = walkaddr(pagetable, va + i);
    80005782:	02091593          	slli	a1,s2,0x20
    80005786:	9181                	srli	a1,a1,0x20
    80005788:	95de                	add	a1,a1,s7
    8000578a:	855a                	mv	a0,s6
    8000578c:	ffffc097          	auipc	ra,0xffffc
    80005790:	92a080e7          	jalr	-1750(ra) # 800010b6 <walkaddr>
    80005794:	862a                	mv	a2,a0
    if(pa == 0)
    80005796:	dd4d                	beqz	a0,80005750 <exec+0xe6>
    if(sz - i < PGSIZE)
    80005798:	412984bb          	subw	s1,s3,s2
    8000579c:	0004879b          	sext.w	a5,s1
    800057a0:	fcfcf0e3          	bgeu	s9,a5,80005760 <exec+0xf6>
    800057a4:	84d6                	mv	s1,s5
    800057a6:	bf6d                	j	80005760 <exec+0xf6>
    sz = sz1;
    800057a8:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057ac:	2d85                	addiw	s11,s11,1
    800057ae:	038d0d1b          	addiw	s10,s10,56
    800057b2:	e8845783          	lhu	a5,-376(s0)
    800057b6:	08fdd663          	bge	s11,a5,80005842 <exec+0x1d8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057ba:	2d01                	sext.w	s10,s10
    800057bc:	03800713          	li	a4,56
    800057c0:	86ea                	mv	a3,s10
    800057c2:	e1840613          	addi	a2,s0,-488
    800057c6:	4581                	li	a1,0
    800057c8:	8552                	mv	a0,s4
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	bea080e7          	jalr	-1046(ra) # 800043b4 <readi>
    800057d2:	03800793          	li	a5,56
    800057d6:	20f51063          	bne	a0,a5,800059d6 <exec+0x36c>
    if(ph.type != ELF_PROG_LOAD)
    800057da:	e1842783          	lw	a5,-488(s0)
    800057de:	4705                	li	a4,1
    800057e0:	fce796e3          	bne	a5,a4,800057ac <exec+0x142>
    if(ph.memsz < ph.filesz)
    800057e4:	e4043483          	ld	s1,-448(s0)
    800057e8:	e3843783          	ld	a5,-456(s0)
    800057ec:	1ef4e963          	bltu	s1,a5,800059de <exec+0x374>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800057f0:	e2843783          	ld	a5,-472(s0)
    800057f4:	94be                	add	s1,s1,a5
    800057f6:	1ef4e863          	bltu	s1,a5,800059e6 <exec+0x37c>
    if(ph.vaddr % PGSIZE != 0)
    800057fa:	df043703          	ld	a4,-528(s0)
    800057fe:	8ff9                	and	a5,a5,a4
    80005800:	1e079763          	bnez	a5,800059ee <exec+0x384>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005804:	e1c42503          	lw	a0,-484(s0)
    80005808:	00000097          	auipc	ra,0x0
    8000580c:	e48080e7          	jalr	-440(ra) # 80005650 <flags2perm>
    80005810:	86aa                	mv	a3,a0
    80005812:	8626                	mv	a2,s1
    80005814:	85ca                	mv	a1,s2
    80005816:	855a                	mv	a0,s6
    80005818:	ffffc097          	auipc	ra,0xffffc
    8000581c:	c62080e7          	jalr	-926(ra) # 8000147a <uvmalloc>
    80005820:	e0a43423          	sd	a0,-504(s0)
    80005824:	1c050963          	beqz	a0,800059f6 <exec+0x38c>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005828:	e2843b83          	ld	s7,-472(s0)
    8000582c:	e2042c03          	lw	s8,-480(s0)
    80005830:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005834:	00098463          	beqz	s3,8000583c <exec+0x1d2>
    80005838:	4901                	li	s2,0
    8000583a:	b7a1                	j	80005782 <exec+0x118>
    sz = sz1;
    8000583c:	e0843903          	ld	s2,-504(s0)
    80005840:	b7b5                	j	800057ac <exec+0x142>
    80005842:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80005844:	8552                	mv	a0,s4
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	b1c080e7          	jalr	-1252(ra) # 80004362 <iunlockput>
  end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	2f6080e7          	jalr	758(ra) # 80004b44 <end_op>
  p = myproc();
    80005856:	ffffc097          	auipc	ra,0xffffc
    8000585a:	4de080e7          	jalr	1246(ra) # 80001d34 <myproc>
    8000585e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005860:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005864:	6985                	lui	s3,0x1
    80005866:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005868:	99ca                	add	s3,s3,s2
    8000586a:	77fd                	lui	a5,0xfffff
    8000586c:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005870:	4691                	li	a3,4
    80005872:	6609                	lui	a2,0x2
    80005874:	964e                	add	a2,a2,s3
    80005876:	85ce                	mv	a1,s3
    80005878:	855a                	mv	a0,s6
    8000587a:	ffffc097          	auipc	ra,0xffffc
    8000587e:	c00080e7          	jalr	-1024(ra) # 8000147a <uvmalloc>
    80005882:	892a                	mv	s2,a0
    80005884:	e0a43423          	sd	a0,-504(s0)
    80005888:	e519                	bnez	a0,80005896 <exec+0x22c>
  if(pagetable)
    8000588a:	e1343423          	sd	s3,-504(s0)
    8000588e:	4a01                	li	s4,0
    80005890:	aaa5                	j	80005a08 <exec+0x39e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005892:	4901                	li	s2,0
    80005894:	bf45                	j	80005844 <exec+0x1da>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005896:	75f9                	lui	a1,0xffffe
    80005898:	95aa                	add	a1,a1,a0
    8000589a:	855a                	mv	a0,s6
    8000589c:	ffffc097          	auipc	ra,0xffffc
    800058a0:	e14080e7          	jalr	-492(ra) # 800016b0 <uvmclear>
  stackbase = sp - PGSIZE;
    800058a4:	7bfd                	lui	s7,0xfffff
    800058a6:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800058a8:	e0043783          	ld	a5,-512(s0)
    800058ac:	6388                	ld	a0,0(a5)
    800058ae:	c52d                	beqz	a0,80005918 <exec+0x2ae>
    800058b0:	e9040993          	addi	s3,s0,-368
    800058b4:	f9040c13          	addi	s8,s0,-112
    800058b8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800058ba:	ffffb097          	auipc	ra,0xffffb
    800058be:	5ee080e7          	jalr	1518(ra) # 80000ea8 <strlen>
    800058c2:	0015079b          	addiw	a5,a0,1
    800058c6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800058ca:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800058ce:	13796863          	bltu	s2,s7,800059fe <exec+0x394>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800058d2:	e0043d03          	ld	s10,-512(s0)
    800058d6:	000d3a03          	ld	s4,0(s10)
    800058da:	8552                	mv	a0,s4
    800058dc:	ffffb097          	auipc	ra,0xffffb
    800058e0:	5cc080e7          	jalr	1484(ra) # 80000ea8 <strlen>
    800058e4:	0015069b          	addiw	a3,a0,1
    800058e8:	8652                	mv	a2,s4
    800058ea:	85ca                	mv	a1,s2
    800058ec:	855a                	mv	a0,s6
    800058ee:	ffffc097          	auipc	ra,0xffffc
    800058f2:	df4080e7          	jalr	-524(ra) # 800016e2 <copyout>
    800058f6:	10054663          	bltz	a0,80005a02 <exec+0x398>
    ustack[argc] = sp;
    800058fa:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800058fe:	0485                	addi	s1,s1,1
    80005900:	008d0793          	addi	a5,s10,8
    80005904:	e0f43023          	sd	a5,-512(s0)
    80005908:	008d3503          	ld	a0,8(s10)
    8000590c:	c909                	beqz	a0,8000591e <exec+0x2b4>
    if(argc >= MAXARG)
    8000590e:	09a1                	addi	s3,s3,8
    80005910:	fb8995e3          	bne	s3,s8,800058ba <exec+0x250>
  ip = 0;
    80005914:	4a01                	li	s4,0
    80005916:	a8cd                	j	80005a08 <exec+0x39e>
  sp = sz;
    80005918:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000591c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000591e:	00349793          	slli	a5,s1,0x3
    80005922:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffd6e40>
    80005926:	97a2                	add	a5,a5,s0
    80005928:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000592c:	00148693          	addi	a3,s1,1
    80005930:	068e                	slli	a3,a3,0x3
    80005932:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005936:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    8000593a:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000593e:	f57966e3          	bltu	s2,s7,8000588a <exec+0x220>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005942:	e9040613          	addi	a2,s0,-368
    80005946:	85ca                	mv	a1,s2
    80005948:	855a                	mv	a0,s6
    8000594a:	ffffc097          	auipc	ra,0xffffc
    8000594e:	d98080e7          	jalr	-616(ra) # 800016e2 <copyout>
    80005952:	0e054863          	bltz	a0,80005a42 <exec+0x3d8>
  p->trapframe->a1 = sp;
    80005956:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000595a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000595e:	df843783          	ld	a5,-520(s0)
    80005962:	0007c703          	lbu	a4,0(a5)
    80005966:	cf11                	beqz	a4,80005982 <exec+0x318>
    80005968:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000596a:	02f00693          	li	a3,47
    8000596e:	a039                	j	8000597c <exec+0x312>
      last = s+1;
    80005970:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005974:	0785                	addi	a5,a5,1
    80005976:	fff7c703          	lbu	a4,-1(a5)
    8000597a:	c701                	beqz	a4,80005982 <exec+0x318>
    if(*s == '/')
    8000597c:	fed71ce3          	bne	a4,a3,80005974 <exec+0x30a>
    80005980:	bfc5                	j	80005970 <exec+0x306>
  safestrcpy(p->name, last, sizeof(p->name));
    80005982:	4641                	li	a2,16
    80005984:	df843583          	ld	a1,-520(s0)
    80005988:	158a8513          	addi	a0,s5,344
    8000598c:	ffffb097          	auipc	ra,0xffffb
    80005990:	4ea080e7          	jalr	1258(ra) # 80000e76 <safestrcpy>
  oldpagetable = p->pagetable;
    80005994:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005998:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000599c:	e0843783          	ld	a5,-504(s0)
    800059a0:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800059a4:	058ab783          	ld	a5,88(s5)
    800059a8:	e6843703          	ld	a4,-408(s0)
    800059ac:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800059ae:	058ab783          	ld	a5,88(s5)
    800059b2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800059b6:	85e6                	mv	a1,s9
    800059b8:	ffffc097          	auipc	ra,0xffffc
    800059bc:	4dc080e7          	jalr	1244(ra) # 80001e94 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800059c0:	0004851b          	sext.w	a0,s1
    800059c4:	79be                	ld	s3,488(sp)
    800059c6:	7a1e                	ld	s4,480(sp)
    800059c8:	6afe                	ld	s5,472(sp)
    800059ca:	6b5e                	ld	s6,464(sp)
    800059cc:	6bbe                	ld	s7,456(sp)
    800059ce:	6c1e                	ld	s8,448(sp)
    800059d0:	7cfa                	ld	s9,440(sp)
    800059d2:	7d5a                	ld	s10,432(sp)
    800059d4:	b305                	j	800056f4 <exec+0x8a>
    800059d6:	e1243423          	sd	s2,-504(s0)
    800059da:	7dba                	ld	s11,424(sp)
    800059dc:	a035                	j	80005a08 <exec+0x39e>
    800059de:	e1243423          	sd	s2,-504(s0)
    800059e2:	7dba                	ld	s11,424(sp)
    800059e4:	a015                	j	80005a08 <exec+0x39e>
    800059e6:	e1243423          	sd	s2,-504(s0)
    800059ea:	7dba                	ld	s11,424(sp)
    800059ec:	a831                	j	80005a08 <exec+0x39e>
    800059ee:	e1243423          	sd	s2,-504(s0)
    800059f2:	7dba                	ld	s11,424(sp)
    800059f4:	a811                	j	80005a08 <exec+0x39e>
    800059f6:	e1243423          	sd	s2,-504(s0)
    800059fa:	7dba                	ld	s11,424(sp)
    800059fc:	a031                	j	80005a08 <exec+0x39e>
  ip = 0;
    800059fe:	4a01                	li	s4,0
    80005a00:	a021                	j	80005a08 <exec+0x39e>
    80005a02:	4a01                	li	s4,0
  if(pagetable)
    80005a04:	a011                	j	80005a08 <exec+0x39e>
    80005a06:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80005a08:	e0843583          	ld	a1,-504(s0)
    80005a0c:	855a                	mv	a0,s6
    80005a0e:	ffffc097          	auipc	ra,0xffffc
    80005a12:	486080e7          	jalr	1158(ra) # 80001e94 <proc_freepagetable>
  return -1;
    80005a16:	557d                	li	a0,-1
  if(ip){
    80005a18:	000a1b63          	bnez	s4,80005a2e <exec+0x3c4>
    80005a1c:	79be                	ld	s3,488(sp)
    80005a1e:	7a1e                	ld	s4,480(sp)
    80005a20:	6afe                	ld	s5,472(sp)
    80005a22:	6b5e                	ld	s6,464(sp)
    80005a24:	6bbe                	ld	s7,456(sp)
    80005a26:	6c1e                	ld	s8,448(sp)
    80005a28:	7cfa                	ld	s9,440(sp)
    80005a2a:	7d5a                	ld	s10,432(sp)
    80005a2c:	b1e1                	j	800056f4 <exec+0x8a>
    80005a2e:	79be                	ld	s3,488(sp)
    80005a30:	6afe                	ld	s5,472(sp)
    80005a32:	6b5e                	ld	s6,464(sp)
    80005a34:	6bbe                	ld	s7,456(sp)
    80005a36:	6c1e                	ld	s8,448(sp)
    80005a38:	7cfa                	ld	s9,440(sp)
    80005a3a:	7d5a                	ld	s10,432(sp)
    80005a3c:	b14d                	j	800056de <exec+0x74>
    80005a3e:	6b5e                	ld	s6,464(sp)
    80005a40:	b979                	j	800056de <exec+0x74>
  sz = sz1;
    80005a42:	e0843983          	ld	s3,-504(s0)
    80005a46:	b591                	j	8000588a <exec+0x220>

0000000080005a48 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005a48:	7179                	addi	sp,sp,-48
    80005a4a:	f406                	sd	ra,40(sp)
    80005a4c:	f022                	sd	s0,32(sp)
    80005a4e:	ec26                	sd	s1,24(sp)
    80005a50:	e84a                	sd	s2,16(sp)
    80005a52:	1800                	addi	s0,sp,48
    80005a54:	892e                	mv	s2,a1
    80005a56:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005a58:	fdc40593          	addi	a1,s0,-36
    80005a5c:	ffffe097          	auipc	ra,0xffffe
    80005a60:	924080e7          	jalr	-1756(ra) # 80003380 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005a64:	fdc42703          	lw	a4,-36(s0)
    80005a68:	47bd                	li	a5,15
    80005a6a:	02e7eb63          	bltu	a5,a4,80005aa0 <argfd+0x58>
    80005a6e:	ffffc097          	auipc	ra,0xffffc
    80005a72:	2c6080e7          	jalr	710(ra) # 80001d34 <myproc>
    80005a76:	fdc42703          	lw	a4,-36(s0)
    80005a7a:	01a70793          	addi	a5,a4,26
    80005a7e:	078e                	slli	a5,a5,0x3
    80005a80:	953e                	add	a0,a0,a5
    80005a82:	611c                	ld	a5,0(a0)
    80005a84:	c385                	beqz	a5,80005aa4 <argfd+0x5c>
    return -1;
  if(pfd)
    80005a86:	00090463          	beqz	s2,80005a8e <argfd+0x46>
    *pfd = fd;
    80005a8a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005a8e:	4501                	li	a0,0
  if(pf)
    80005a90:	c091                	beqz	s1,80005a94 <argfd+0x4c>
    *pf = f;
    80005a92:	e09c                	sd	a5,0(s1)
}
    80005a94:	70a2                	ld	ra,40(sp)
    80005a96:	7402                	ld	s0,32(sp)
    80005a98:	64e2                	ld	s1,24(sp)
    80005a9a:	6942                	ld	s2,16(sp)
    80005a9c:	6145                	addi	sp,sp,48
    80005a9e:	8082                	ret
    return -1;
    80005aa0:	557d                	li	a0,-1
    80005aa2:	bfcd                	j	80005a94 <argfd+0x4c>
    80005aa4:	557d                	li	a0,-1
    80005aa6:	b7fd                	j	80005a94 <argfd+0x4c>

0000000080005aa8 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005aa8:	1101                	addi	sp,sp,-32
    80005aaa:	ec06                	sd	ra,24(sp)
    80005aac:	e822                	sd	s0,16(sp)
    80005aae:	e426                	sd	s1,8(sp)
    80005ab0:	1000                	addi	s0,sp,32
    80005ab2:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005ab4:	ffffc097          	auipc	ra,0xffffc
    80005ab8:	280080e7          	jalr	640(ra) # 80001d34 <myproc>
    80005abc:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005abe:	0d050793          	addi	a5,a0,208
    80005ac2:	4501                	li	a0,0
    80005ac4:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005ac6:	6398                	ld	a4,0(a5)
    80005ac8:	cb19                	beqz	a4,80005ade <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005aca:	2505                	addiw	a0,a0,1
    80005acc:	07a1                	addi	a5,a5,8
    80005ace:	fed51ce3          	bne	a0,a3,80005ac6 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005ad2:	557d                	li	a0,-1
}
    80005ad4:	60e2                	ld	ra,24(sp)
    80005ad6:	6442                	ld	s0,16(sp)
    80005ad8:	64a2                	ld	s1,8(sp)
    80005ada:	6105                	addi	sp,sp,32
    80005adc:	8082                	ret
      p->ofile[fd] = f;
    80005ade:	01a50793          	addi	a5,a0,26
    80005ae2:	078e                	slli	a5,a5,0x3
    80005ae4:	963e                	add	a2,a2,a5
    80005ae6:	e204                	sd	s1,0(a2)
      return fd;
    80005ae8:	b7f5                	j	80005ad4 <fdalloc+0x2c>

0000000080005aea <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005aea:	715d                	addi	sp,sp,-80
    80005aec:	e486                	sd	ra,72(sp)
    80005aee:	e0a2                	sd	s0,64(sp)
    80005af0:	fc26                	sd	s1,56(sp)
    80005af2:	f84a                	sd	s2,48(sp)
    80005af4:	f44e                	sd	s3,40(sp)
    80005af6:	ec56                	sd	s5,24(sp)
    80005af8:	e85a                	sd	s6,16(sp)
    80005afa:	0880                	addi	s0,sp,80
    80005afc:	8b2e                	mv	s6,a1
    80005afe:	89b2                	mv	s3,a2
    80005b00:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005b02:	fb040593          	addi	a1,s0,-80
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	de2080e7          	jalr	-542(ra) # 800048e8 <nameiparent>
    80005b0e:	84aa                	mv	s1,a0
    80005b10:	14050e63          	beqz	a0,80005c6c <create+0x182>
    return 0;

  ilock(dp);
    80005b14:	ffffe097          	auipc	ra,0xffffe
    80005b18:	5e8080e7          	jalr	1512(ra) # 800040fc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005b1c:	4601                	li	a2,0
    80005b1e:	fb040593          	addi	a1,s0,-80
    80005b22:	8526                	mv	a0,s1
    80005b24:	fffff097          	auipc	ra,0xfffff
    80005b28:	ae4080e7          	jalr	-1308(ra) # 80004608 <dirlookup>
    80005b2c:	8aaa                	mv	s5,a0
    80005b2e:	c539                	beqz	a0,80005b7c <create+0x92>
    iunlockput(dp);
    80005b30:	8526                	mv	a0,s1
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	830080e7          	jalr	-2000(ra) # 80004362 <iunlockput>
    ilock(ip);
    80005b3a:	8556                	mv	a0,s5
    80005b3c:	ffffe097          	auipc	ra,0xffffe
    80005b40:	5c0080e7          	jalr	1472(ra) # 800040fc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005b44:	4789                	li	a5,2
    80005b46:	02fb1463          	bne	s6,a5,80005b6e <create+0x84>
    80005b4a:	044ad783          	lhu	a5,68(s5)
    80005b4e:	37f9                	addiw	a5,a5,-2
    80005b50:	17c2                	slli	a5,a5,0x30
    80005b52:	93c1                	srli	a5,a5,0x30
    80005b54:	4705                	li	a4,1
    80005b56:	00f76c63          	bltu	a4,a5,80005b6e <create+0x84>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005b5a:	8556                	mv	a0,s5
    80005b5c:	60a6                	ld	ra,72(sp)
    80005b5e:	6406                	ld	s0,64(sp)
    80005b60:	74e2                	ld	s1,56(sp)
    80005b62:	7942                	ld	s2,48(sp)
    80005b64:	79a2                	ld	s3,40(sp)
    80005b66:	6ae2                	ld	s5,24(sp)
    80005b68:	6b42                	ld	s6,16(sp)
    80005b6a:	6161                	addi	sp,sp,80
    80005b6c:	8082                	ret
    iunlockput(ip);
    80005b6e:	8556                	mv	a0,s5
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	7f2080e7          	jalr	2034(ra) # 80004362 <iunlockput>
    return 0;
    80005b78:	4a81                	li	s5,0
    80005b7a:	b7c5                	j	80005b5a <create+0x70>
    80005b7c:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80005b7e:	85da                	mv	a1,s6
    80005b80:	4088                	lw	a0,0(s1)
    80005b82:	ffffe097          	auipc	ra,0xffffe
    80005b86:	3d6080e7          	jalr	982(ra) # 80003f58 <ialloc>
    80005b8a:	8a2a                	mv	s4,a0
    80005b8c:	c531                	beqz	a0,80005bd8 <create+0xee>
  ilock(ip);
    80005b8e:	ffffe097          	auipc	ra,0xffffe
    80005b92:	56e080e7          	jalr	1390(ra) # 800040fc <ilock>
  ip->major = major;
    80005b96:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005b9a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005b9e:	4905                	li	s2,1
    80005ba0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005ba4:	8552                	mv	a0,s4
    80005ba6:	ffffe097          	auipc	ra,0xffffe
    80005baa:	48a080e7          	jalr	1162(ra) # 80004030 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005bae:	032b0d63          	beq	s6,s2,80005be8 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005bb2:	004a2603          	lw	a2,4(s4)
    80005bb6:	fb040593          	addi	a1,s0,-80
    80005bba:	8526                	mv	a0,s1
    80005bbc:	fffff097          	auipc	ra,0xfffff
    80005bc0:	c5c080e7          	jalr	-932(ra) # 80004818 <dirlink>
    80005bc4:	08054163          	bltz	a0,80005c46 <create+0x15c>
  iunlockput(dp);
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	798080e7          	jalr	1944(ra) # 80004362 <iunlockput>
  return ip;
    80005bd2:	8ad2                	mv	s5,s4
    80005bd4:	7a02                	ld	s4,32(sp)
    80005bd6:	b751                	j	80005b5a <create+0x70>
    iunlockput(dp);
    80005bd8:	8526                	mv	a0,s1
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	788080e7          	jalr	1928(ra) # 80004362 <iunlockput>
    return 0;
    80005be2:	8ad2                	mv	s5,s4
    80005be4:	7a02                	ld	s4,32(sp)
    80005be6:	bf95                	j	80005b5a <create+0x70>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005be8:	004a2603          	lw	a2,4(s4)
    80005bec:	00003597          	auipc	a1,0x3
    80005bf0:	a2458593          	addi	a1,a1,-1500 # 80008610 <etext+0x610>
    80005bf4:	8552                	mv	a0,s4
    80005bf6:	fffff097          	auipc	ra,0xfffff
    80005bfa:	c22080e7          	jalr	-990(ra) # 80004818 <dirlink>
    80005bfe:	04054463          	bltz	a0,80005c46 <create+0x15c>
    80005c02:	40d0                	lw	a2,4(s1)
    80005c04:	00003597          	auipc	a1,0x3
    80005c08:	a1458593          	addi	a1,a1,-1516 # 80008618 <etext+0x618>
    80005c0c:	8552                	mv	a0,s4
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	c0a080e7          	jalr	-1014(ra) # 80004818 <dirlink>
    80005c16:	02054863          	bltz	a0,80005c46 <create+0x15c>
  if(dirlink(dp, name, ip->inum) < 0)
    80005c1a:	004a2603          	lw	a2,4(s4)
    80005c1e:	fb040593          	addi	a1,s0,-80
    80005c22:	8526                	mv	a0,s1
    80005c24:	fffff097          	auipc	ra,0xfffff
    80005c28:	bf4080e7          	jalr	-1036(ra) # 80004818 <dirlink>
    80005c2c:	00054d63          	bltz	a0,80005c46 <create+0x15c>
    dp->nlink++;  // for ".."
    80005c30:	04a4d783          	lhu	a5,74(s1)
    80005c34:	2785                	addiw	a5,a5,1
    80005c36:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	3f4080e7          	jalr	1012(ra) # 80004030 <iupdate>
    80005c44:	b751                	j	80005bc8 <create+0xde>
  ip->nlink = 0;
    80005c46:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005c4a:	8552                	mv	a0,s4
    80005c4c:	ffffe097          	auipc	ra,0xffffe
    80005c50:	3e4080e7          	jalr	996(ra) # 80004030 <iupdate>
  iunlockput(ip);
    80005c54:	8552                	mv	a0,s4
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	70c080e7          	jalr	1804(ra) # 80004362 <iunlockput>
  iunlockput(dp);
    80005c5e:	8526                	mv	a0,s1
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	702080e7          	jalr	1794(ra) # 80004362 <iunlockput>
  return 0;
    80005c68:	7a02                	ld	s4,32(sp)
    80005c6a:	bdc5                	j	80005b5a <create+0x70>
    return 0;
    80005c6c:	8aaa                	mv	s5,a0
    80005c6e:	b5f5                	j	80005b5a <create+0x70>

0000000080005c70 <sys_dup>:
{
    80005c70:	7179                	addi	sp,sp,-48
    80005c72:	f406                	sd	ra,40(sp)
    80005c74:	f022                	sd	s0,32(sp)
    80005c76:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005c78:	fd840613          	addi	a2,s0,-40
    80005c7c:	4581                	li	a1,0
    80005c7e:	4501                	li	a0,0
    80005c80:	00000097          	auipc	ra,0x0
    80005c84:	dc8080e7          	jalr	-568(ra) # 80005a48 <argfd>
    return -1;
    80005c88:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005c8a:	02054763          	bltz	a0,80005cb8 <sys_dup+0x48>
    80005c8e:	ec26                	sd	s1,24(sp)
    80005c90:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80005c92:	fd843903          	ld	s2,-40(s0)
    80005c96:	854a                	mv	a0,s2
    80005c98:	00000097          	auipc	ra,0x0
    80005c9c:	e10080e7          	jalr	-496(ra) # 80005aa8 <fdalloc>
    80005ca0:	84aa                	mv	s1,a0
    return -1;
    80005ca2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005ca4:	00054f63          	bltz	a0,80005cc2 <sys_dup+0x52>
  filedup(f);
    80005ca8:	854a                	mv	a0,s2
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	298080e7          	jalr	664(ra) # 80004f42 <filedup>
  return fd;
    80005cb2:	87a6                	mv	a5,s1
    80005cb4:	64e2                	ld	s1,24(sp)
    80005cb6:	6942                	ld	s2,16(sp)
}
    80005cb8:	853e                	mv	a0,a5
    80005cba:	70a2                	ld	ra,40(sp)
    80005cbc:	7402                	ld	s0,32(sp)
    80005cbe:	6145                	addi	sp,sp,48
    80005cc0:	8082                	ret
    80005cc2:	64e2                	ld	s1,24(sp)
    80005cc4:	6942                	ld	s2,16(sp)
    80005cc6:	bfcd                	j	80005cb8 <sys_dup+0x48>

0000000080005cc8 <sys_read>:
{
    80005cc8:	7179                	addi	sp,sp,-48
    80005cca:	f406                	sd	ra,40(sp)
    80005ccc:	f022                	sd	s0,32(sp)
    80005cce:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005cd0:	fd840593          	addi	a1,s0,-40
    80005cd4:	4505                	li	a0,1
    80005cd6:	ffffd097          	auipc	ra,0xffffd
    80005cda:	6ca080e7          	jalr	1738(ra) # 800033a0 <argaddr>
  argint(2, &n);
    80005cde:	fe440593          	addi	a1,s0,-28
    80005ce2:	4509                	li	a0,2
    80005ce4:	ffffd097          	auipc	ra,0xffffd
    80005ce8:	69c080e7          	jalr	1692(ra) # 80003380 <argint>
  if(argfd(0, 0, &f) < 0)
    80005cec:	fe840613          	addi	a2,s0,-24
    80005cf0:	4581                	li	a1,0
    80005cf2:	4501                	li	a0,0
    80005cf4:	00000097          	auipc	ra,0x0
    80005cf8:	d54080e7          	jalr	-684(ra) # 80005a48 <argfd>
    80005cfc:	87aa                	mv	a5,a0
    return -1;
    80005cfe:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d00:	0007cc63          	bltz	a5,80005d18 <sys_read+0x50>
  return fileread(f, p, n);
    80005d04:	fe442603          	lw	a2,-28(s0)
    80005d08:	fd843583          	ld	a1,-40(s0)
    80005d0c:	fe843503          	ld	a0,-24(s0)
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	3d8080e7          	jalr	984(ra) # 800050e8 <fileread>
}
    80005d18:	70a2                	ld	ra,40(sp)
    80005d1a:	7402                	ld	s0,32(sp)
    80005d1c:	6145                	addi	sp,sp,48
    80005d1e:	8082                	ret

0000000080005d20 <sys_write>:
{
    80005d20:	7179                	addi	sp,sp,-48
    80005d22:	f406                	sd	ra,40(sp)
    80005d24:	f022                	sd	s0,32(sp)
    80005d26:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005d28:	fd840593          	addi	a1,s0,-40
    80005d2c:	4505                	li	a0,1
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	672080e7          	jalr	1650(ra) # 800033a0 <argaddr>
  argint(2, &n);
    80005d36:	fe440593          	addi	a1,s0,-28
    80005d3a:	4509                	li	a0,2
    80005d3c:	ffffd097          	auipc	ra,0xffffd
    80005d40:	644080e7          	jalr	1604(ra) # 80003380 <argint>
  if(argfd(0, 0, &f) < 0)
    80005d44:	fe840613          	addi	a2,s0,-24
    80005d48:	4581                	li	a1,0
    80005d4a:	4501                	li	a0,0
    80005d4c:	00000097          	auipc	ra,0x0
    80005d50:	cfc080e7          	jalr	-772(ra) # 80005a48 <argfd>
    80005d54:	87aa                	mv	a5,a0
    return -1;
    80005d56:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005d58:	0007cc63          	bltz	a5,80005d70 <sys_write+0x50>
  return filewrite(f, p, n);
    80005d5c:	fe442603          	lw	a2,-28(s0)
    80005d60:	fd843583          	ld	a1,-40(s0)
    80005d64:	fe843503          	ld	a0,-24(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	452080e7          	jalr	1106(ra) # 800051ba <filewrite>
}
    80005d70:	70a2                	ld	ra,40(sp)
    80005d72:	7402                	ld	s0,32(sp)
    80005d74:	6145                	addi	sp,sp,48
    80005d76:	8082                	ret

0000000080005d78 <sys_close>:
{
    80005d78:	1101                	addi	sp,sp,-32
    80005d7a:	ec06                	sd	ra,24(sp)
    80005d7c:	e822                	sd	s0,16(sp)
    80005d7e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005d80:	fe040613          	addi	a2,s0,-32
    80005d84:	fec40593          	addi	a1,s0,-20
    80005d88:	4501                	li	a0,0
    80005d8a:	00000097          	auipc	ra,0x0
    80005d8e:	cbe080e7          	jalr	-834(ra) # 80005a48 <argfd>
    return -1;
    80005d92:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005d94:	02054463          	bltz	a0,80005dbc <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	f9c080e7          	jalr	-100(ra) # 80001d34 <myproc>
    80005da0:	fec42783          	lw	a5,-20(s0)
    80005da4:	07e9                	addi	a5,a5,26
    80005da6:	078e                	slli	a5,a5,0x3
    80005da8:	953e                	add	a0,a0,a5
    80005daa:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005dae:	fe043503          	ld	a0,-32(s0)
    80005db2:	fffff097          	auipc	ra,0xfffff
    80005db6:	1e2080e7          	jalr	482(ra) # 80004f94 <fileclose>
  return 0;
    80005dba:	4781                	li	a5,0
}
    80005dbc:	853e                	mv	a0,a5
    80005dbe:	60e2                	ld	ra,24(sp)
    80005dc0:	6442                	ld	s0,16(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <sys_fstat>:
{
    80005dc6:	1101                	addi	sp,sp,-32
    80005dc8:	ec06                	sd	ra,24(sp)
    80005dca:	e822                	sd	s0,16(sp)
    80005dcc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005dce:	fe040593          	addi	a1,s0,-32
    80005dd2:	4505                	li	a0,1
    80005dd4:	ffffd097          	auipc	ra,0xffffd
    80005dd8:	5cc080e7          	jalr	1484(ra) # 800033a0 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005ddc:	fe840613          	addi	a2,s0,-24
    80005de0:	4581                	li	a1,0
    80005de2:	4501                	li	a0,0
    80005de4:	00000097          	auipc	ra,0x0
    80005de8:	c64080e7          	jalr	-924(ra) # 80005a48 <argfd>
    80005dec:	87aa                	mv	a5,a0
    return -1;
    80005dee:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005df0:	0007ca63          	bltz	a5,80005e04 <sys_fstat+0x3e>
  return filestat(f, st);
    80005df4:	fe043583          	ld	a1,-32(s0)
    80005df8:	fe843503          	ld	a0,-24(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	27a080e7          	jalr	634(ra) # 80005076 <filestat>
}
    80005e04:	60e2                	ld	ra,24(sp)
    80005e06:	6442                	ld	s0,16(sp)
    80005e08:	6105                	addi	sp,sp,32
    80005e0a:	8082                	ret

0000000080005e0c <sys_link>:
{
    80005e0c:	7169                	addi	sp,sp,-304
    80005e0e:	f606                	sd	ra,296(sp)
    80005e10:	f222                	sd	s0,288(sp)
    80005e12:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e14:	08000613          	li	a2,128
    80005e18:	ed040593          	addi	a1,s0,-304
    80005e1c:	4501                	li	a0,0
    80005e1e:	ffffd097          	auipc	ra,0xffffd
    80005e22:	5a2080e7          	jalr	1442(ra) # 800033c0 <argstr>
    return -1;
    80005e26:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e28:	12054663          	bltz	a0,80005f54 <sys_link+0x148>
    80005e2c:	08000613          	li	a2,128
    80005e30:	f5040593          	addi	a1,s0,-176
    80005e34:	4505                	li	a0,1
    80005e36:	ffffd097          	auipc	ra,0xffffd
    80005e3a:	58a080e7          	jalr	1418(ra) # 800033c0 <argstr>
    return -1;
    80005e3e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005e40:	10054a63          	bltz	a0,80005f54 <sys_link+0x148>
    80005e44:	ee26                	sd	s1,280(sp)
  begin_op();
    80005e46:	fffff097          	auipc	ra,0xfffff
    80005e4a:	c84080e7          	jalr	-892(ra) # 80004aca <begin_op>
  if((ip = namei(old)) == 0){
    80005e4e:	ed040513          	addi	a0,s0,-304
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	a78080e7          	jalr	-1416(ra) # 800048ca <namei>
    80005e5a:	84aa                	mv	s1,a0
    80005e5c:	c949                	beqz	a0,80005eee <sys_link+0xe2>
  ilock(ip);
    80005e5e:	ffffe097          	auipc	ra,0xffffe
    80005e62:	29e080e7          	jalr	670(ra) # 800040fc <ilock>
  if(ip->type == T_DIR){
    80005e66:	04449703          	lh	a4,68(s1)
    80005e6a:	4785                	li	a5,1
    80005e6c:	08f70863          	beq	a4,a5,80005efc <sys_link+0xf0>
    80005e70:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005e72:	04a4d783          	lhu	a5,74(s1)
    80005e76:	2785                	addiw	a5,a5,1
    80005e78:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005e7c:	8526                	mv	a0,s1
    80005e7e:	ffffe097          	auipc	ra,0xffffe
    80005e82:	1b2080e7          	jalr	434(ra) # 80004030 <iupdate>
  iunlock(ip);
    80005e86:	8526                	mv	a0,s1
    80005e88:	ffffe097          	auipc	ra,0xffffe
    80005e8c:	33a080e7          	jalr	826(ra) # 800041c2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005e90:	fd040593          	addi	a1,s0,-48
    80005e94:	f5040513          	addi	a0,s0,-176
    80005e98:	fffff097          	auipc	ra,0xfffff
    80005e9c:	a50080e7          	jalr	-1456(ra) # 800048e8 <nameiparent>
    80005ea0:	892a                	mv	s2,a0
    80005ea2:	cd35                	beqz	a0,80005f1e <sys_link+0x112>
  ilock(dp);
    80005ea4:	ffffe097          	auipc	ra,0xffffe
    80005ea8:	258080e7          	jalr	600(ra) # 800040fc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005eac:	00092703          	lw	a4,0(s2)
    80005eb0:	409c                	lw	a5,0(s1)
    80005eb2:	06f71163          	bne	a4,a5,80005f14 <sys_link+0x108>
    80005eb6:	40d0                	lw	a2,4(s1)
    80005eb8:	fd040593          	addi	a1,s0,-48
    80005ebc:	854a                	mv	a0,s2
    80005ebe:	fffff097          	auipc	ra,0xfffff
    80005ec2:	95a080e7          	jalr	-1702(ra) # 80004818 <dirlink>
    80005ec6:	04054763          	bltz	a0,80005f14 <sys_link+0x108>
  iunlockput(dp);
    80005eca:	854a                	mv	a0,s2
    80005ecc:	ffffe097          	auipc	ra,0xffffe
    80005ed0:	496080e7          	jalr	1174(ra) # 80004362 <iunlockput>
  iput(ip);
    80005ed4:	8526                	mv	a0,s1
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	3e4080e7          	jalr	996(ra) # 800042ba <iput>
  end_op();
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	c66080e7          	jalr	-922(ra) # 80004b44 <end_op>
  return 0;
    80005ee6:	4781                	li	a5,0
    80005ee8:	64f2                	ld	s1,280(sp)
    80005eea:	6952                	ld	s2,272(sp)
    80005eec:	a0a5                	j	80005f54 <sys_link+0x148>
    end_op();
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	c56080e7          	jalr	-938(ra) # 80004b44 <end_op>
    return -1;
    80005ef6:	57fd                	li	a5,-1
    80005ef8:	64f2                	ld	s1,280(sp)
    80005efa:	a8a9                	j	80005f54 <sys_link+0x148>
    iunlockput(ip);
    80005efc:	8526                	mv	a0,s1
    80005efe:	ffffe097          	auipc	ra,0xffffe
    80005f02:	464080e7          	jalr	1124(ra) # 80004362 <iunlockput>
    end_op();
    80005f06:	fffff097          	auipc	ra,0xfffff
    80005f0a:	c3e080e7          	jalr	-962(ra) # 80004b44 <end_op>
    return -1;
    80005f0e:	57fd                	li	a5,-1
    80005f10:	64f2                	ld	s1,280(sp)
    80005f12:	a089                	j	80005f54 <sys_link+0x148>
    iunlockput(dp);
    80005f14:	854a                	mv	a0,s2
    80005f16:	ffffe097          	auipc	ra,0xffffe
    80005f1a:	44c080e7          	jalr	1100(ra) # 80004362 <iunlockput>
  ilock(ip);
    80005f1e:	8526                	mv	a0,s1
    80005f20:	ffffe097          	auipc	ra,0xffffe
    80005f24:	1dc080e7          	jalr	476(ra) # 800040fc <ilock>
  ip->nlink--;
    80005f28:	04a4d783          	lhu	a5,74(s1)
    80005f2c:	37fd                	addiw	a5,a5,-1
    80005f2e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005f32:	8526                	mv	a0,s1
    80005f34:	ffffe097          	auipc	ra,0xffffe
    80005f38:	0fc080e7          	jalr	252(ra) # 80004030 <iupdate>
  iunlockput(ip);
    80005f3c:	8526                	mv	a0,s1
    80005f3e:	ffffe097          	auipc	ra,0xffffe
    80005f42:	424080e7          	jalr	1060(ra) # 80004362 <iunlockput>
  end_op();
    80005f46:	fffff097          	auipc	ra,0xfffff
    80005f4a:	bfe080e7          	jalr	-1026(ra) # 80004b44 <end_op>
  return -1;
    80005f4e:	57fd                	li	a5,-1
    80005f50:	64f2                	ld	s1,280(sp)
    80005f52:	6952                	ld	s2,272(sp)
}
    80005f54:	853e                	mv	a0,a5
    80005f56:	70b2                	ld	ra,296(sp)
    80005f58:	7412                	ld	s0,288(sp)
    80005f5a:	6155                	addi	sp,sp,304
    80005f5c:	8082                	ret

0000000080005f5e <sys_unlink>:
{
    80005f5e:	7151                	addi	sp,sp,-240
    80005f60:	f586                	sd	ra,232(sp)
    80005f62:	f1a2                	sd	s0,224(sp)
    80005f64:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005f66:	08000613          	li	a2,128
    80005f6a:	f3040593          	addi	a1,s0,-208
    80005f6e:	4501                	li	a0,0
    80005f70:	ffffd097          	auipc	ra,0xffffd
    80005f74:	450080e7          	jalr	1104(ra) # 800033c0 <argstr>
    80005f78:	1a054a63          	bltz	a0,8000612c <sys_unlink+0x1ce>
    80005f7c:	eda6                	sd	s1,216(sp)
  begin_op();
    80005f7e:	fffff097          	auipc	ra,0xfffff
    80005f82:	b4c080e7          	jalr	-1204(ra) # 80004aca <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005f86:	fb040593          	addi	a1,s0,-80
    80005f8a:	f3040513          	addi	a0,s0,-208
    80005f8e:	fffff097          	auipc	ra,0xfffff
    80005f92:	95a080e7          	jalr	-1702(ra) # 800048e8 <nameiparent>
    80005f96:	84aa                	mv	s1,a0
    80005f98:	cd71                	beqz	a0,80006074 <sys_unlink+0x116>
  ilock(dp);
    80005f9a:	ffffe097          	auipc	ra,0xffffe
    80005f9e:	162080e7          	jalr	354(ra) # 800040fc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005fa2:	00002597          	auipc	a1,0x2
    80005fa6:	66e58593          	addi	a1,a1,1646 # 80008610 <etext+0x610>
    80005faa:	fb040513          	addi	a0,s0,-80
    80005fae:	ffffe097          	auipc	ra,0xffffe
    80005fb2:	640080e7          	jalr	1600(ra) # 800045ee <namecmp>
    80005fb6:	14050c63          	beqz	a0,8000610e <sys_unlink+0x1b0>
    80005fba:	00002597          	auipc	a1,0x2
    80005fbe:	65e58593          	addi	a1,a1,1630 # 80008618 <etext+0x618>
    80005fc2:	fb040513          	addi	a0,s0,-80
    80005fc6:	ffffe097          	auipc	ra,0xffffe
    80005fca:	628080e7          	jalr	1576(ra) # 800045ee <namecmp>
    80005fce:	14050063          	beqz	a0,8000610e <sys_unlink+0x1b0>
    80005fd2:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005fd4:	f2c40613          	addi	a2,s0,-212
    80005fd8:	fb040593          	addi	a1,s0,-80
    80005fdc:	8526                	mv	a0,s1
    80005fde:	ffffe097          	auipc	ra,0xffffe
    80005fe2:	62a080e7          	jalr	1578(ra) # 80004608 <dirlookup>
    80005fe6:	892a                	mv	s2,a0
    80005fe8:	12050263          	beqz	a0,8000610c <sys_unlink+0x1ae>
  ilock(ip);
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	110080e7          	jalr	272(ra) # 800040fc <ilock>
  if(ip->nlink < 1)
    80005ff4:	04a91783          	lh	a5,74(s2)
    80005ff8:	08f05563          	blez	a5,80006082 <sys_unlink+0x124>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ffc:	04491703          	lh	a4,68(s2)
    80006000:	4785                	li	a5,1
    80006002:	08f70963          	beq	a4,a5,80006094 <sys_unlink+0x136>
  memset(&de, 0, sizeof(de));
    80006006:	4641                	li	a2,16
    80006008:	4581                	li	a1,0
    8000600a:	fc040513          	addi	a0,s0,-64
    8000600e:	ffffb097          	auipc	ra,0xffffb
    80006012:	d26080e7          	jalr	-730(ra) # 80000d34 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006016:	4741                	li	a4,16
    80006018:	f2c42683          	lw	a3,-212(s0)
    8000601c:	fc040613          	addi	a2,s0,-64
    80006020:	4581                	li	a1,0
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	4a0080e7          	jalr	1184(ra) # 800044c4 <writei>
    8000602c:	47c1                	li	a5,16
    8000602e:	0af51b63          	bne	a0,a5,800060e4 <sys_unlink+0x186>
  if(ip->type == T_DIR){
    80006032:	04491703          	lh	a4,68(s2)
    80006036:	4785                	li	a5,1
    80006038:	0af70f63          	beq	a4,a5,800060f6 <sys_unlink+0x198>
  iunlockput(dp);
    8000603c:	8526                	mv	a0,s1
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	324080e7          	jalr	804(ra) # 80004362 <iunlockput>
  ip->nlink--;
    80006046:	04a95783          	lhu	a5,74(s2)
    8000604a:	37fd                	addiw	a5,a5,-1
    8000604c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006050:	854a                	mv	a0,s2
    80006052:	ffffe097          	auipc	ra,0xffffe
    80006056:	fde080e7          	jalr	-34(ra) # 80004030 <iupdate>
  iunlockput(ip);
    8000605a:	854a                	mv	a0,s2
    8000605c:	ffffe097          	auipc	ra,0xffffe
    80006060:	306080e7          	jalr	774(ra) # 80004362 <iunlockput>
  end_op();
    80006064:	fffff097          	auipc	ra,0xfffff
    80006068:	ae0080e7          	jalr	-1312(ra) # 80004b44 <end_op>
  return 0;
    8000606c:	4501                	li	a0,0
    8000606e:	64ee                	ld	s1,216(sp)
    80006070:	694e                	ld	s2,208(sp)
    80006072:	a84d                	j	80006124 <sys_unlink+0x1c6>
    end_op();
    80006074:	fffff097          	auipc	ra,0xfffff
    80006078:	ad0080e7          	jalr	-1328(ra) # 80004b44 <end_op>
    return -1;
    8000607c:	557d                	li	a0,-1
    8000607e:	64ee                	ld	s1,216(sp)
    80006080:	a055                	j	80006124 <sys_unlink+0x1c6>
    80006082:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    80006084:	00002517          	auipc	a0,0x2
    80006088:	59c50513          	addi	a0,a0,1436 # 80008620 <etext+0x620>
    8000608c:	ffffa097          	auipc	ra,0xffffa
    80006090:	4d4080e7          	jalr	1236(ra) # 80000560 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006094:	04c92703          	lw	a4,76(s2)
    80006098:	02000793          	li	a5,32
    8000609c:	f6e7f5e3          	bgeu	a5,a4,80006006 <sys_unlink+0xa8>
    800060a0:	e5ce                	sd	s3,200(sp)
    800060a2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800060a6:	4741                	li	a4,16
    800060a8:	86ce                	mv	a3,s3
    800060aa:	f1840613          	addi	a2,s0,-232
    800060ae:	4581                	li	a1,0
    800060b0:	854a                	mv	a0,s2
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	302080e7          	jalr	770(ra) # 800043b4 <readi>
    800060ba:	47c1                	li	a5,16
    800060bc:	00f51c63          	bne	a0,a5,800060d4 <sys_unlink+0x176>
    if(de.inum != 0)
    800060c0:	f1845783          	lhu	a5,-232(s0)
    800060c4:	e7b5                	bnez	a5,80006130 <sys_unlink+0x1d2>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800060c6:	29c1                	addiw	s3,s3,16
    800060c8:	04c92783          	lw	a5,76(s2)
    800060cc:	fcf9ede3          	bltu	s3,a5,800060a6 <sys_unlink+0x148>
    800060d0:	69ae                	ld	s3,200(sp)
    800060d2:	bf15                	j	80006006 <sys_unlink+0xa8>
      panic("isdirempty: readi");
    800060d4:	00002517          	auipc	a0,0x2
    800060d8:	56450513          	addi	a0,a0,1380 # 80008638 <etext+0x638>
    800060dc:	ffffa097          	auipc	ra,0xffffa
    800060e0:	484080e7          	jalr	1156(ra) # 80000560 <panic>
    800060e4:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    800060e6:	00002517          	auipc	a0,0x2
    800060ea:	56a50513          	addi	a0,a0,1386 # 80008650 <etext+0x650>
    800060ee:	ffffa097          	auipc	ra,0xffffa
    800060f2:	472080e7          	jalr	1138(ra) # 80000560 <panic>
    dp->nlink--;
    800060f6:	04a4d783          	lhu	a5,74(s1)
    800060fa:	37fd                	addiw	a5,a5,-1
    800060fc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006100:	8526                	mv	a0,s1
    80006102:	ffffe097          	auipc	ra,0xffffe
    80006106:	f2e080e7          	jalr	-210(ra) # 80004030 <iupdate>
    8000610a:	bf0d                	j	8000603c <sys_unlink+0xde>
    8000610c:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    8000610e:	8526                	mv	a0,s1
    80006110:	ffffe097          	auipc	ra,0xffffe
    80006114:	252080e7          	jalr	594(ra) # 80004362 <iunlockput>
  end_op();
    80006118:	fffff097          	auipc	ra,0xfffff
    8000611c:	a2c080e7          	jalr	-1492(ra) # 80004b44 <end_op>
  return -1;
    80006120:	557d                	li	a0,-1
    80006122:	64ee                	ld	s1,216(sp)
}
    80006124:	70ae                	ld	ra,232(sp)
    80006126:	740e                	ld	s0,224(sp)
    80006128:	616d                	addi	sp,sp,240
    8000612a:	8082                	ret
    return -1;
    8000612c:	557d                	li	a0,-1
    8000612e:	bfdd                	j	80006124 <sys_unlink+0x1c6>
    iunlockput(ip);
    80006130:	854a                	mv	a0,s2
    80006132:	ffffe097          	auipc	ra,0xffffe
    80006136:	230080e7          	jalr	560(ra) # 80004362 <iunlockput>
    goto bad;
    8000613a:	694e                	ld	s2,208(sp)
    8000613c:	69ae                	ld	s3,200(sp)
    8000613e:	bfc1                	j	8000610e <sys_unlink+0x1b0>

0000000080006140 <sys_open>:

uint64
sys_open(void)
{
    80006140:	7131                	addi	sp,sp,-192
    80006142:	fd06                	sd	ra,184(sp)
    80006144:	f922                	sd	s0,176(sp)
    80006146:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80006148:	f4c40593          	addi	a1,s0,-180
    8000614c:	4505                	li	a0,1
    8000614e:	ffffd097          	auipc	ra,0xffffd
    80006152:	232080e7          	jalr	562(ra) # 80003380 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006156:	08000613          	li	a2,128
    8000615a:	f5040593          	addi	a1,s0,-176
    8000615e:	4501                	li	a0,0
    80006160:	ffffd097          	auipc	ra,0xffffd
    80006164:	260080e7          	jalr	608(ra) # 800033c0 <argstr>
    80006168:	87aa                	mv	a5,a0
    return -1;
    8000616a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000616c:	0a07ce63          	bltz	a5,80006228 <sys_open+0xe8>
    80006170:	f526                	sd	s1,168(sp)

  begin_op();
    80006172:	fffff097          	auipc	ra,0xfffff
    80006176:	958080e7          	jalr	-1704(ra) # 80004aca <begin_op>

  if(omode & O_CREATE){
    8000617a:	f4c42783          	lw	a5,-180(s0)
    8000617e:	2007f793          	andi	a5,a5,512
    80006182:	cfd5                	beqz	a5,8000623e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006184:	4681                	li	a3,0
    80006186:	4601                	li	a2,0
    80006188:	4589                	li	a1,2
    8000618a:	f5040513          	addi	a0,s0,-176
    8000618e:	00000097          	auipc	ra,0x0
    80006192:	95c080e7          	jalr	-1700(ra) # 80005aea <create>
    80006196:	84aa                	mv	s1,a0
    if(ip == 0){
    80006198:	cd41                	beqz	a0,80006230 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000619a:	04449703          	lh	a4,68(s1)
    8000619e:	478d                	li	a5,3
    800061a0:	00f71763          	bne	a4,a5,800061ae <sys_open+0x6e>
    800061a4:	0464d703          	lhu	a4,70(s1)
    800061a8:	47a5                	li	a5,9
    800061aa:	0ee7e163          	bltu	a5,a4,8000628c <sys_open+0x14c>
    800061ae:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800061b0:	fffff097          	auipc	ra,0xfffff
    800061b4:	d28080e7          	jalr	-728(ra) # 80004ed8 <filealloc>
    800061b8:	892a                	mv	s2,a0
    800061ba:	c97d                	beqz	a0,800062b0 <sys_open+0x170>
    800061bc:	ed4e                	sd	s3,152(sp)
    800061be:	00000097          	auipc	ra,0x0
    800061c2:	8ea080e7          	jalr	-1814(ra) # 80005aa8 <fdalloc>
    800061c6:	89aa                	mv	s3,a0
    800061c8:	0c054e63          	bltz	a0,800062a4 <sys_open+0x164>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800061cc:	04449703          	lh	a4,68(s1)
    800061d0:	478d                	li	a5,3
    800061d2:	0ef70c63          	beq	a4,a5,800062ca <sys_open+0x18a>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800061d6:	4789                	li	a5,2
    800061d8:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    800061dc:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    800061e0:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    800061e4:	f4c42783          	lw	a5,-180(s0)
    800061e8:	0017c713          	xori	a4,a5,1
    800061ec:	8b05                	andi	a4,a4,1
    800061ee:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800061f2:	0037f713          	andi	a4,a5,3
    800061f6:	00e03733          	snez	a4,a4
    800061fa:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800061fe:	4007f793          	andi	a5,a5,1024
    80006202:	c791                	beqz	a5,8000620e <sys_open+0xce>
    80006204:	04449703          	lh	a4,68(s1)
    80006208:	4789                	li	a5,2
    8000620a:	0cf70763          	beq	a4,a5,800062d8 <sys_open+0x198>
    itrunc(ip);
  }

  iunlock(ip);
    8000620e:	8526                	mv	a0,s1
    80006210:	ffffe097          	auipc	ra,0xffffe
    80006214:	fb2080e7          	jalr	-78(ra) # 800041c2 <iunlock>
  end_op();
    80006218:	fffff097          	auipc	ra,0xfffff
    8000621c:	92c080e7          	jalr	-1748(ra) # 80004b44 <end_op>

  return fd;
    80006220:	854e                	mv	a0,s3
    80006222:	74aa                	ld	s1,168(sp)
    80006224:	790a                	ld	s2,160(sp)
    80006226:	69ea                	ld	s3,152(sp)
}
    80006228:	70ea                	ld	ra,184(sp)
    8000622a:	744a                	ld	s0,176(sp)
    8000622c:	6129                	addi	sp,sp,192
    8000622e:	8082                	ret
      end_op();
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	914080e7          	jalr	-1772(ra) # 80004b44 <end_op>
      return -1;
    80006238:	557d                	li	a0,-1
    8000623a:	74aa                	ld	s1,168(sp)
    8000623c:	b7f5                	j	80006228 <sys_open+0xe8>
    if((ip = namei(path)) == 0){
    8000623e:	f5040513          	addi	a0,s0,-176
    80006242:	ffffe097          	auipc	ra,0xffffe
    80006246:	688080e7          	jalr	1672(ra) # 800048ca <namei>
    8000624a:	84aa                	mv	s1,a0
    8000624c:	c90d                	beqz	a0,8000627e <sys_open+0x13e>
    ilock(ip);
    8000624e:	ffffe097          	auipc	ra,0xffffe
    80006252:	eae080e7          	jalr	-338(ra) # 800040fc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006256:	04449703          	lh	a4,68(s1)
    8000625a:	4785                	li	a5,1
    8000625c:	f2f71fe3          	bne	a4,a5,8000619a <sys_open+0x5a>
    80006260:	f4c42783          	lw	a5,-180(s0)
    80006264:	d7a9                	beqz	a5,800061ae <sys_open+0x6e>
      iunlockput(ip);
    80006266:	8526                	mv	a0,s1
    80006268:	ffffe097          	auipc	ra,0xffffe
    8000626c:	0fa080e7          	jalr	250(ra) # 80004362 <iunlockput>
      end_op();
    80006270:	fffff097          	auipc	ra,0xfffff
    80006274:	8d4080e7          	jalr	-1836(ra) # 80004b44 <end_op>
      return -1;
    80006278:	557d                	li	a0,-1
    8000627a:	74aa                	ld	s1,168(sp)
    8000627c:	b775                	j	80006228 <sys_open+0xe8>
      end_op();
    8000627e:	fffff097          	auipc	ra,0xfffff
    80006282:	8c6080e7          	jalr	-1850(ra) # 80004b44 <end_op>
      return -1;
    80006286:	557d                	li	a0,-1
    80006288:	74aa                	ld	s1,168(sp)
    8000628a:	bf79                	j	80006228 <sys_open+0xe8>
    iunlockput(ip);
    8000628c:	8526                	mv	a0,s1
    8000628e:	ffffe097          	auipc	ra,0xffffe
    80006292:	0d4080e7          	jalr	212(ra) # 80004362 <iunlockput>
    end_op();
    80006296:	fffff097          	auipc	ra,0xfffff
    8000629a:	8ae080e7          	jalr	-1874(ra) # 80004b44 <end_op>
    return -1;
    8000629e:	557d                	li	a0,-1
    800062a0:	74aa                	ld	s1,168(sp)
    800062a2:	b759                	j	80006228 <sys_open+0xe8>
      fileclose(f);
    800062a4:	854a                	mv	a0,s2
    800062a6:	fffff097          	auipc	ra,0xfffff
    800062aa:	cee080e7          	jalr	-786(ra) # 80004f94 <fileclose>
    800062ae:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800062b0:	8526                	mv	a0,s1
    800062b2:	ffffe097          	auipc	ra,0xffffe
    800062b6:	0b0080e7          	jalr	176(ra) # 80004362 <iunlockput>
    end_op();
    800062ba:	fffff097          	auipc	ra,0xfffff
    800062be:	88a080e7          	jalr	-1910(ra) # 80004b44 <end_op>
    return -1;
    800062c2:	557d                	li	a0,-1
    800062c4:	74aa                	ld	s1,168(sp)
    800062c6:	790a                	ld	s2,160(sp)
    800062c8:	b785                	j	80006228 <sys_open+0xe8>
    f->type = FD_DEVICE;
    800062ca:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800062ce:	04649783          	lh	a5,70(s1)
    800062d2:	02f91223          	sh	a5,36(s2)
    800062d6:	b729                	j	800061e0 <sys_open+0xa0>
    itrunc(ip);
    800062d8:	8526                	mv	a0,s1
    800062da:	ffffe097          	auipc	ra,0xffffe
    800062de:	f34080e7          	jalr	-204(ra) # 8000420e <itrunc>
    800062e2:	b735                	j	8000620e <sys_open+0xce>

00000000800062e4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800062e4:	7175                	addi	sp,sp,-144
    800062e6:	e506                	sd	ra,136(sp)
    800062e8:	e122                	sd	s0,128(sp)
    800062ea:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800062ec:	ffffe097          	auipc	ra,0xffffe
    800062f0:	7de080e7          	jalr	2014(ra) # 80004aca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800062f4:	08000613          	li	a2,128
    800062f8:	f7040593          	addi	a1,s0,-144
    800062fc:	4501                	li	a0,0
    800062fe:	ffffd097          	auipc	ra,0xffffd
    80006302:	0c2080e7          	jalr	194(ra) # 800033c0 <argstr>
    80006306:	02054963          	bltz	a0,80006338 <sys_mkdir+0x54>
    8000630a:	4681                	li	a3,0
    8000630c:	4601                	li	a2,0
    8000630e:	4585                	li	a1,1
    80006310:	f7040513          	addi	a0,s0,-144
    80006314:	fffff097          	auipc	ra,0xfffff
    80006318:	7d6080e7          	jalr	2006(ra) # 80005aea <create>
    8000631c:	cd11                	beqz	a0,80006338 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000631e:	ffffe097          	auipc	ra,0xffffe
    80006322:	044080e7          	jalr	68(ra) # 80004362 <iunlockput>
  end_op();
    80006326:	fffff097          	auipc	ra,0xfffff
    8000632a:	81e080e7          	jalr	-2018(ra) # 80004b44 <end_op>
  return 0;
    8000632e:	4501                	li	a0,0
}
    80006330:	60aa                	ld	ra,136(sp)
    80006332:	640a                	ld	s0,128(sp)
    80006334:	6149                	addi	sp,sp,144
    80006336:	8082                	ret
    end_op();
    80006338:	fffff097          	auipc	ra,0xfffff
    8000633c:	80c080e7          	jalr	-2036(ra) # 80004b44 <end_op>
    return -1;
    80006340:	557d                	li	a0,-1
    80006342:	b7fd                	j	80006330 <sys_mkdir+0x4c>

0000000080006344 <sys_mknod>:

uint64
sys_mknod(void)
{
    80006344:	7135                	addi	sp,sp,-160
    80006346:	ed06                	sd	ra,152(sp)
    80006348:	e922                	sd	s0,144(sp)
    8000634a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000634c:	ffffe097          	auipc	ra,0xffffe
    80006350:	77e080e7          	jalr	1918(ra) # 80004aca <begin_op>
  argint(1, &major);
    80006354:	f6c40593          	addi	a1,s0,-148
    80006358:	4505                	li	a0,1
    8000635a:	ffffd097          	auipc	ra,0xffffd
    8000635e:	026080e7          	jalr	38(ra) # 80003380 <argint>
  argint(2, &minor);
    80006362:	f6840593          	addi	a1,s0,-152
    80006366:	4509                	li	a0,2
    80006368:	ffffd097          	auipc	ra,0xffffd
    8000636c:	018080e7          	jalr	24(ra) # 80003380 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006370:	08000613          	li	a2,128
    80006374:	f7040593          	addi	a1,s0,-144
    80006378:	4501                	li	a0,0
    8000637a:	ffffd097          	auipc	ra,0xffffd
    8000637e:	046080e7          	jalr	70(ra) # 800033c0 <argstr>
    80006382:	02054b63          	bltz	a0,800063b8 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006386:	f6841683          	lh	a3,-152(s0)
    8000638a:	f6c41603          	lh	a2,-148(s0)
    8000638e:	458d                	li	a1,3
    80006390:	f7040513          	addi	a0,s0,-144
    80006394:	fffff097          	auipc	ra,0xfffff
    80006398:	756080e7          	jalr	1878(ra) # 80005aea <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000639c:	cd11                	beqz	a0,800063b8 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000639e:	ffffe097          	auipc	ra,0xffffe
    800063a2:	fc4080e7          	jalr	-60(ra) # 80004362 <iunlockput>
  end_op();
    800063a6:	ffffe097          	auipc	ra,0xffffe
    800063aa:	79e080e7          	jalr	1950(ra) # 80004b44 <end_op>
  return 0;
    800063ae:	4501                	li	a0,0
}
    800063b0:	60ea                	ld	ra,152(sp)
    800063b2:	644a                	ld	s0,144(sp)
    800063b4:	610d                	addi	sp,sp,160
    800063b6:	8082                	ret
    end_op();
    800063b8:	ffffe097          	auipc	ra,0xffffe
    800063bc:	78c080e7          	jalr	1932(ra) # 80004b44 <end_op>
    return -1;
    800063c0:	557d                	li	a0,-1
    800063c2:	b7fd                	j	800063b0 <sys_mknod+0x6c>

00000000800063c4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800063c4:	7135                	addi	sp,sp,-160
    800063c6:	ed06                	sd	ra,152(sp)
    800063c8:	e922                	sd	s0,144(sp)
    800063ca:	e14a                	sd	s2,128(sp)
    800063cc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800063ce:	ffffc097          	auipc	ra,0xffffc
    800063d2:	966080e7          	jalr	-1690(ra) # 80001d34 <myproc>
    800063d6:	892a                	mv	s2,a0
  
  begin_op();
    800063d8:	ffffe097          	auipc	ra,0xffffe
    800063dc:	6f2080e7          	jalr	1778(ra) # 80004aca <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800063e0:	08000613          	li	a2,128
    800063e4:	f6040593          	addi	a1,s0,-160
    800063e8:	4501                	li	a0,0
    800063ea:	ffffd097          	auipc	ra,0xffffd
    800063ee:	fd6080e7          	jalr	-42(ra) # 800033c0 <argstr>
    800063f2:	04054d63          	bltz	a0,8000644c <sys_chdir+0x88>
    800063f6:	e526                	sd	s1,136(sp)
    800063f8:	f6040513          	addi	a0,s0,-160
    800063fc:	ffffe097          	auipc	ra,0xffffe
    80006400:	4ce080e7          	jalr	1230(ra) # 800048ca <namei>
    80006404:	84aa                	mv	s1,a0
    80006406:	c131                	beqz	a0,8000644a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006408:	ffffe097          	auipc	ra,0xffffe
    8000640c:	cf4080e7          	jalr	-780(ra) # 800040fc <ilock>
  if(ip->type != T_DIR){
    80006410:	04449703          	lh	a4,68(s1)
    80006414:	4785                	li	a5,1
    80006416:	04f71163          	bne	a4,a5,80006458 <sys_chdir+0x94>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    8000641a:	8526                	mv	a0,s1
    8000641c:	ffffe097          	auipc	ra,0xffffe
    80006420:	da6080e7          	jalr	-602(ra) # 800041c2 <iunlock>
  iput(p->cwd);
    80006424:	15093503          	ld	a0,336(s2)
    80006428:	ffffe097          	auipc	ra,0xffffe
    8000642c:	e92080e7          	jalr	-366(ra) # 800042ba <iput>
  end_op();
    80006430:	ffffe097          	auipc	ra,0xffffe
    80006434:	714080e7          	jalr	1812(ra) # 80004b44 <end_op>
  p->cwd = ip;
    80006438:	14993823          	sd	s1,336(s2)
  return 0;
    8000643c:	4501                	li	a0,0
    8000643e:	64aa                	ld	s1,136(sp)
}
    80006440:	60ea                	ld	ra,152(sp)
    80006442:	644a                	ld	s0,144(sp)
    80006444:	690a                	ld	s2,128(sp)
    80006446:	610d                	addi	sp,sp,160
    80006448:	8082                	ret
    8000644a:	64aa                	ld	s1,136(sp)
    end_op();
    8000644c:	ffffe097          	auipc	ra,0xffffe
    80006450:	6f8080e7          	jalr	1784(ra) # 80004b44 <end_op>
    return -1;
    80006454:	557d                	li	a0,-1
    80006456:	b7ed                	j	80006440 <sys_chdir+0x7c>
    iunlockput(ip);
    80006458:	8526                	mv	a0,s1
    8000645a:	ffffe097          	auipc	ra,0xffffe
    8000645e:	f08080e7          	jalr	-248(ra) # 80004362 <iunlockput>
    end_op();
    80006462:	ffffe097          	auipc	ra,0xffffe
    80006466:	6e2080e7          	jalr	1762(ra) # 80004b44 <end_op>
    return -1;
    8000646a:	557d                	li	a0,-1
    8000646c:	64aa                	ld	s1,136(sp)
    8000646e:	bfc9                	j	80006440 <sys_chdir+0x7c>

0000000080006470 <sys_exec>:

uint64
sys_exec(void)
{
    80006470:	7121                	addi	sp,sp,-448
    80006472:	ff06                	sd	ra,440(sp)
    80006474:	fb22                	sd	s0,432(sp)
    80006476:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006478:	e4840593          	addi	a1,s0,-440
    8000647c:	4505                	li	a0,1
    8000647e:	ffffd097          	auipc	ra,0xffffd
    80006482:	f22080e7          	jalr	-222(ra) # 800033a0 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006486:	08000613          	li	a2,128
    8000648a:	f5040593          	addi	a1,s0,-176
    8000648e:	4501                	li	a0,0
    80006490:	ffffd097          	auipc	ra,0xffffd
    80006494:	f30080e7          	jalr	-208(ra) # 800033c0 <argstr>
    80006498:	87aa                	mv	a5,a0
    return -1;
    8000649a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000649c:	0e07c263          	bltz	a5,80006580 <sys_exec+0x110>
    800064a0:	f726                	sd	s1,424(sp)
    800064a2:	f34a                	sd	s2,416(sp)
    800064a4:	ef4e                	sd	s3,408(sp)
    800064a6:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    800064a8:	10000613          	li	a2,256
    800064ac:	4581                	li	a1,0
    800064ae:	e5040513          	addi	a0,s0,-432
    800064b2:	ffffb097          	auipc	ra,0xffffb
    800064b6:	882080e7          	jalr	-1918(ra) # 80000d34 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800064ba:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800064be:	89a6                	mv	s3,s1
    800064c0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800064c2:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800064c6:	00391513          	slli	a0,s2,0x3
    800064ca:	e4040593          	addi	a1,s0,-448
    800064ce:	e4843783          	ld	a5,-440(s0)
    800064d2:	953e                	add	a0,a0,a5
    800064d4:	ffffd097          	auipc	ra,0xffffd
    800064d8:	e0e080e7          	jalr	-498(ra) # 800032e2 <fetchaddr>
    800064dc:	02054a63          	bltz	a0,80006510 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800064e0:	e4043783          	ld	a5,-448(s0)
    800064e4:	c7b9                	beqz	a5,80006532 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800064e6:	ffffa097          	auipc	ra,0xffffa
    800064ea:	662080e7          	jalr	1634(ra) # 80000b48 <kalloc>
    800064ee:	85aa                	mv	a1,a0
    800064f0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800064f4:	cd11                	beqz	a0,80006510 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800064f6:	6605                	lui	a2,0x1
    800064f8:	e4043503          	ld	a0,-448(s0)
    800064fc:	ffffd097          	auipc	ra,0xffffd
    80006500:	e38080e7          	jalr	-456(ra) # 80003334 <fetchstr>
    80006504:	00054663          	bltz	a0,80006510 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80006508:	0905                	addi	s2,s2,1
    8000650a:	09a1                	addi	s3,s3,8
    8000650c:	fb491de3          	bne	s2,s4,800064c6 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006510:	f5040913          	addi	s2,s0,-176
    80006514:	6088                	ld	a0,0(s1)
    80006516:	c125                	beqz	a0,80006576 <sys_exec+0x106>
    kfree(argv[i]);
    80006518:	ffffa097          	auipc	ra,0xffffa
    8000651c:	532080e7          	jalr	1330(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006520:	04a1                	addi	s1,s1,8
    80006522:	ff2499e3          	bne	s1,s2,80006514 <sys_exec+0xa4>
  return -1;
    80006526:	557d                	li	a0,-1
    80006528:	74ba                	ld	s1,424(sp)
    8000652a:	791a                	ld	s2,416(sp)
    8000652c:	69fa                	ld	s3,408(sp)
    8000652e:	6a5a                	ld	s4,400(sp)
    80006530:	a881                	j	80006580 <sys_exec+0x110>
      argv[i] = 0;
    80006532:	0009079b          	sext.w	a5,s2
    80006536:	078e                	slli	a5,a5,0x3
    80006538:	fd078793          	addi	a5,a5,-48
    8000653c:	97a2                	add	a5,a5,s0
    8000653e:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80006542:	e5040593          	addi	a1,s0,-432
    80006546:	f5040513          	addi	a0,s0,-176
    8000654a:	fffff097          	auipc	ra,0xfffff
    8000654e:	120080e7          	jalr	288(ra) # 8000566a <exec>
    80006552:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006554:	f5040993          	addi	s3,s0,-176
    80006558:	6088                	ld	a0,0(s1)
    8000655a:	c901                	beqz	a0,8000656a <sys_exec+0xfa>
    kfree(argv[i]);
    8000655c:	ffffa097          	auipc	ra,0xffffa
    80006560:	4ee080e7          	jalr	1262(ra) # 80000a4a <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006564:	04a1                	addi	s1,s1,8
    80006566:	ff3499e3          	bne	s1,s3,80006558 <sys_exec+0xe8>
  return ret;
    8000656a:	854a                	mv	a0,s2
    8000656c:	74ba                	ld	s1,424(sp)
    8000656e:	791a                	ld	s2,416(sp)
    80006570:	69fa                	ld	s3,408(sp)
    80006572:	6a5a                	ld	s4,400(sp)
    80006574:	a031                	j	80006580 <sys_exec+0x110>
  return -1;
    80006576:	557d                	li	a0,-1
    80006578:	74ba                	ld	s1,424(sp)
    8000657a:	791a                	ld	s2,416(sp)
    8000657c:	69fa                	ld	s3,408(sp)
    8000657e:	6a5a                	ld	s4,400(sp)
}
    80006580:	70fa                	ld	ra,440(sp)
    80006582:	745a                	ld	s0,432(sp)
    80006584:	6139                	addi	sp,sp,448
    80006586:	8082                	ret

0000000080006588 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006588:	7139                	addi	sp,sp,-64
    8000658a:	fc06                	sd	ra,56(sp)
    8000658c:	f822                	sd	s0,48(sp)
    8000658e:	f426                	sd	s1,40(sp)
    80006590:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006592:	ffffb097          	auipc	ra,0xffffb
    80006596:	7a2080e7          	jalr	1954(ra) # 80001d34 <myproc>
    8000659a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    8000659c:	fd840593          	addi	a1,s0,-40
    800065a0:	4501                	li	a0,0
    800065a2:	ffffd097          	auipc	ra,0xffffd
    800065a6:	dfe080e7          	jalr	-514(ra) # 800033a0 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800065aa:	fc840593          	addi	a1,s0,-56
    800065ae:	fd040513          	addi	a0,s0,-48
    800065b2:	fffff097          	auipc	ra,0xfffff
    800065b6:	d50080e7          	jalr	-688(ra) # 80005302 <pipealloc>
    return -1;
    800065ba:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800065bc:	0c054463          	bltz	a0,80006684 <sys_pipe+0xfc>
  fd0 = -1;
    800065c0:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800065c4:	fd043503          	ld	a0,-48(s0)
    800065c8:	fffff097          	auipc	ra,0xfffff
    800065cc:	4e0080e7          	jalr	1248(ra) # 80005aa8 <fdalloc>
    800065d0:	fca42223          	sw	a0,-60(s0)
    800065d4:	08054b63          	bltz	a0,8000666a <sys_pipe+0xe2>
    800065d8:	fc843503          	ld	a0,-56(s0)
    800065dc:	fffff097          	auipc	ra,0xfffff
    800065e0:	4cc080e7          	jalr	1228(ra) # 80005aa8 <fdalloc>
    800065e4:	fca42023          	sw	a0,-64(s0)
    800065e8:	06054863          	bltz	a0,80006658 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800065ec:	4691                	li	a3,4
    800065ee:	fc440613          	addi	a2,s0,-60
    800065f2:	fd843583          	ld	a1,-40(s0)
    800065f6:	68a8                	ld	a0,80(s1)
    800065f8:	ffffb097          	auipc	ra,0xffffb
    800065fc:	0ea080e7          	jalr	234(ra) # 800016e2 <copyout>
    80006600:	02054063          	bltz	a0,80006620 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006604:	4691                	li	a3,4
    80006606:	fc040613          	addi	a2,s0,-64
    8000660a:	fd843583          	ld	a1,-40(s0)
    8000660e:	0591                	addi	a1,a1,4
    80006610:	68a8                	ld	a0,80(s1)
    80006612:	ffffb097          	auipc	ra,0xffffb
    80006616:	0d0080e7          	jalr	208(ra) # 800016e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000661a:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000661c:	06055463          	bgez	a0,80006684 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006620:	fc442783          	lw	a5,-60(s0)
    80006624:	07e9                	addi	a5,a5,26
    80006626:	078e                	slli	a5,a5,0x3
    80006628:	97a6                	add	a5,a5,s1
    8000662a:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000662e:	fc042783          	lw	a5,-64(s0)
    80006632:	07e9                	addi	a5,a5,26
    80006634:	078e                	slli	a5,a5,0x3
    80006636:	94be                	add	s1,s1,a5
    80006638:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000663c:	fd043503          	ld	a0,-48(s0)
    80006640:	fffff097          	auipc	ra,0xfffff
    80006644:	954080e7          	jalr	-1708(ra) # 80004f94 <fileclose>
    fileclose(wf);
    80006648:	fc843503          	ld	a0,-56(s0)
    8000664c:	fffff097          	auipc	ra,0xfffff
    80006650:	948080e7          	jalr	-1720(ra) # 80004f94 <fileclose>
    return -1;
    80006654:	57fd                	li	a5,-1
    80006656:	a03d                	j	80006684 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006658:	fc442783          	lw	a5,-60(s0)
    8000665c:	0007c763          	bltz	a5,8000666a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006660:	07e9                	addi	a5,a5,26
    80006662:	078e                	slli	a5,a5,0x3
    80006664:	97a6                	add	a5,a5,s1
    80006666:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000666a:	fd043503          	ld	a0,-48(s0)
    8000666e:	fffff097          	auipc	ra,0xfffff
    80006672:	926080e7          	jalr	-1754(ra) # 80004f94 <fileclose>
    fileclose(wf);
    80006676:	fc843503          	ld	a0,-56(s0)
    8000667a:	fffff097          	auipc	ra,0xfffff
    8000667e:	91a080e7          	jalr	-1766(ra) # 80004f94 <fileclose>
    return -1;
    80006682:	57fd                	li	a5,-1
}
    80006684:	853e                	mv	a0,a5
    80006686:	70e2                	ld	ra,56(sp)
    80006688:	7442                	ld	s0,48(sp)
    8000668a:	74a2                	ld	s1,40(sp)
    8000668c:	6121                	addi	sp,sp,64
    8000668e:	8082                	ret

0000000080006690 <kernelvec>:
    80006690:	7111                	addi	sp,sp,-256
    80006692:	e006                	sd	ra,0(sp)
    80006694:	e40a                	sd	sp,8(sp)
    80006696:	e80e                	sd	gp,16(sp)
    80006698:	ec12                	sd	tp,24(sp)
    8000669a:	f016                	sd	t0,32(sp)
    8000669c:	f41a                	sd	t1,40(sp)
    8000669e:	f81e                	sd	t2,48(sp)
    800066a0:	fc22                	sd	s0,56(sp)
    800066a2:	e0a6                	sd	s1,64(sp)
    800066a4:	e4aa                	sd	a0,72(sp)
    800066a6:	e8ae                	sd	a1,80(sp)
    800066a8:	ecb2                	sd	a2,88(sp)
    800066aa:	f0b6                	sd	a3,96(sp)
    800066ac:	f4ba                	sd	a4,104(sp)
    800066ae:	f8be                	sd	a5,112(sp)
    800066b0:	fcc2                	sd	a6,120(sp)
    800066b2:	e146                	sd	a7,128(sp)
    800066b4:	e54a                	sd	s2,136(sp)
    800066b6:	e94e                	sd	s3,144(sp)
    800066b8:	ed52                	sd	s4,152(sp)
    800066ba:	f156                	sd	s5,160(sp)
    800066bc:	f55a                	sd	s6,168(sp)
    800066be:	f95e                	sd	s7,176(sp)
    800066c0:	fd62                	sd	s8,184(sp)
    800066c2:	e1e6                	sd	s9,192(sp)
    800066c4:	e5ea                	sd	s10,200(sp)
    800066c6:	e9ee                	sd	s11,208(sp)
    800066c8:	edf2                	sd	t3,216(sp)
    800066ca:	f1f6                	sd	t4,224(sp)
    800066cc:	f5fa                	sd	t5,232(sp)
    800066ce:	f9fe                	sd	t6,240(sp)
    800066d0:	adffc0ef          	jal	800031ae <kerneltrap>
    800066d4:	6082                	ld	ra,0(sp)
    800066d6:	6122                	ld	sp,8(sp)
    800066d8:	61c2                	ld	gp,16(sp)
    800066da:	7282                	ld	t0,32(sp)
    800066dc:	7322                	ld	t1,40(sp)
    800066de:	73c2                	ld	t2,48(sp)
    800066e0:	7462                	ld	s0,56(sp)
    800066e2:	6486                	ld	s1,64(sp)
    800066e4:	6526                	ld	a0,72(sp)
    800066e6:	65c6                	ld	a1,80(sp)
    800066e8:	6666                	ld	a2,88(sp)
    800066ea:	7686                	ld	a3,96(sp)
    800066ec:	7726                	ld	a4,104(sp)
    800066ee:	77c6                	ld	a5,112(sp)
    800066f0:	7866                	ld	a6,120(sp)
    800066f2:	688a                	ld	a7,128(sp)
    800066f4:	692a                	ld	s2,136(sp)
    800066f6:	69ca                	ld	s3,144(sp)
    800066f8:	6a6a                	ld	s4,152(sp)
    800066fa:	7a8a                	ld	s5,160(sp)
    800066fc:	7b2a                	ld	s6,168(sp)
    800066fe:	7bca                	ld	s7,176(sp)
    80006700:	7c6a                	ld	s8,184(sp)
    80006702:	6c8e                	ld	s9,192(sp)
    80006704:	6d2e                	ld	s10,200(sp)
    80006706:	6dce                	ld	s11,208(sp)
    80006708:	6e6e                	ld	t3,216(sp)
    8000670a:	7e8e                	ld	t4,224(sp)
    8000670c:	7f2e                	ld	t5,232(sp)
    8000670e:	7fce                	ld	t6,240(sp)
    80006710:	6111                	addi	sp,sp,256
    80006712:	10200073          	sret
    80006716:	00000013          	nop
    8000671a:	00000013          	nop
    8000671e:	0001                	nop

0000000080006720 <timervec>:
    80006720:	34051573          	csrrw	a0,mscratch,a0
    80006724:	e10c                	sd	a1,0(a0)
    80006726:	e510                	sd	a2,8(a0)
    80006728:	e914                	sd	a3,16(a0)
    8000672a:	6d0c                	ld	a1,24(a0)
    8000672c:	7110                	ld	a2,32(a0)
    8000672e:	6194                	ld	a3,0(a1)
    80006730:	96b2                	add	a3,a3,a2
    80006732:	e194                	sd	a3,0(a1)
    80006734:	4589                	li	a1,2
    80006736:	14459073          	csrw	sip,a1
    8000673a:	6914                	ld	a3,16(a0)
    8000673c:	6510                	ld	a2,8(a0)
    8000673e:	610c                	ld	a1,0(a0)
    80006740:	34051573          	csrrw	a0,mscratch,a0
    80006744:	30200073          	mret
	...

000000008000674a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000674a:	1141                	addi	sp,sp,-16
    8000674c:	e422                	sd	s0,8(sp)
    8000674e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006750:	0c0007b7          	lui	a5,0xc000
    80006754:	4705                	li	a4,1
    80006756:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006758:	0c0007b7          	lui	a5,0xc000
    8000675c:	c3d8                	sw	a4,4(a5)
}
    8000675e:	6422                	ld	s0,8(sp)
    80006760:	0141                	addi	sp,sp,16
    80006762:	8082                	ret

0000000080006764 <plicinithart>:

void
plicinithart(void)
{
    80006764:	1141                	addi	sp,sp,-16
    80006766:	e406                	sd	ra,8(sp)
    80006768:	e022                	sd	s0,0(sp)
    8000676a:	0800                	addi	s0,sp,16
  int hart = cpuid();
    8000676c:	ffffb097          	auipc	ra,0xffffb
    80006770:	59c080e7          	jalr	1436(ra) # 80001d08 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006774:	0085171b          	slliw	a4,a0,0x8
    80006778:	0c0027b7          	lui	a5,0xc002
    8000677c:	97ba                	add	a5,a5,a4
    8000677e:	40200713          	li	a4,1026
    80006782:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006786:	00d5151b          	slliw	a0,a0,0xd
    8000678a:	0c2017b7          	lui	a5,0xc201
    8000678e:	97aa                	add	a5,a5,a0
    80006790:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006794:	60a2                	ld	ra,8(sp)
    80006796:	6402                	ld	s0,0(sp)
    80006798:	0141                	addi	sp,sp,16
    8000679a:	8082                	ret

000000008000679c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000679c:	1141                	addi	sp,sp,-16
    8000679e:	e406                	sd	ra,8(sp)
    800067a0:	e022                	sd	s0,0(sp)
    800067a2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800067a4:	ffffb097          	auipc	ra,0xffffb
    800067a8:	564080e7          	jalr	1380(ra) # 80001d08 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800067ac:	00d5151b          	slliw	a0,a0,0xd
    800067b0:	0c2017b7          	lui	a5,0xc201
    800067b4:	97aa                	add	a5,a5,a0
  return irq;
}
    800067b6:	43c8                	lw	a0,4(a5)
    800067b8:	60a2                	ld	ra,8(sp)
    800067ba:	6402                	ld	s0,0(sp)
    800067bc:	0141                	addi	sp,sp,16
    800067be:	8082                	ret

00000000800067c0 <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800067c0:	1101                	addi	sp,sp,-32
    800067c2:	ec06                	sd	ra,24(sp)
    800067c4:	e822                	sd	s0,16(sp)
    800067c6:	e426                	sd	s1,8(sp)
    800067c8:	1000                	addi	s0,sp,32
    800067ca:	84aa                	mv	s1,a0
  int hart = cpuid();
    800067cc:	ffffb097          	auipc	ra,0xffffb
    800067d0:	53c080e7          	jalr	1340(ra) # 80001d08 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800067d4:	00d5151b          	slliw	a0,a0,0xd
    800067d8:	0c2017b7          	lui	a5,0xc201
    800067dc:	97aa                	add	a5,a5,a0
    800067de:	c3c4                	sw	s1,4(a5)
}
    800067e0:	60e2                	ld	ra,24(sp)
    800067e2:	6442                	ld	s0,16(sp)
    800067e4:	64a2                	ld	s1,8(sp)
    800067e6:	6105                	addi	sp,sp,32
    800067e8:	8082                	ret

00000000800067ea <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800067ea:	1141                	addi	sp,sp,-16
    800067ec:	e406                	sd	ra,8(sp)
    800067ee:	e022                	sd	s0,0(sp)
    800067f0:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800067f2:	479d                	li	a5,7
    800067f4:	04a7cc63          	blt	a5,a0,8000684c <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800067f8:	00022797          	auipc	a5,0x22
    800067fc:	81878793          	addi	a5,a5,-2024 # 80028010 <disk>
    80006800:	97aa                	add	a5,a5,a0
    80006802:	0187c783          	lbu	a5,24(a5)
    80006806:	ebb9                	bnez	a5,8000685c <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006808:	00451693          	slli	a3,a0,0x4
    8000680c:	00022797          	auipc	a5,0x22
    80006810:	80478793          	addi	a5,a5,-2044 # 80028010 <disk>
    80006814:	6398                	ld	a4,0(a5)
    80006816:	9736                	add	a4,a4,a3
    80006818:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    8000681c:	6398                	ld	a4,0(a5)
    8000681e:	9736                	add	a4,a4,a3
    80006820:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006824:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006828:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    8000682c:	97aa                	add	a5,a5,a0
    8000682e:	4705                	li	a4,1
    80006830:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006834:	00021517          	auipc	a0,0x21
    80006838:	7f450513          	addi	a0,a0,2036 # 80028028 <disk+0x18>
    8000683c:	ffffc097          	auipc	ra,0xffffc
    80006840:	d98080e7          	jalr	-616(ra) # 800025d4 <wakeup>
}
    80006844:	60a2                	ld	ra,8(sp)
    80006846:	6402                	ld	s0,0(sp)
    80006848:	0141                	addi	sp,sp,16
    8000684a:	8082                	ret
    panic("free_desc 1");
    8000684c:	00002517          	auipc	a0,0x2
    80006850:	e1450513          	addi	a0,a0,-492 # 80008660 <etext+0x660>
    80006854:	ffffa097          	auipc	ra,0xffffa
    80006858:	d0c080e7          	jalr	-756(ra) # 80000560 <panic>
    panic("free_desc 2");
    8000685c:	00002517          	auipc	a0,0x2
    80006860:	e1450513          	addi	a0,a0,-492 # 80008670 <etext+0x670>
    80006864:	ffffa097          	auipc	ra,0xffffa
    80006868:	cfc080e7          	jalr	-772(ra) # 80000560 <panic>

000000008000686c <virtio_disk_init>:
{
    8000686c:	1101                	addi	sp,sp,-32
    8000686e:	ec06                	sd	ra,24(sp)
    80006870:	e822                	sd	s0,16(sp)
    80006872:	e426                	sd	s1,8(sp)
    80006874:	e04a                	sd	s2,0(sp)
    80006876:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006878:	00002597          	auipc	a1,0x2
    8000687c:	e0858593          	addi	a1,a1,-504 # 80008680 <etext+0x680>
    80006880:	00022517          	auipc	a0,0x22
    80006884:	8b850513          	addi	a0,a0,-1864 # 80028138 <disk+0x128>
    80006888:	ffffa097          	auipc	ra,0xffffa
    8000688c:	320080e7          	jalr	800(ra) # 80000ba8 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006890:	100017b7          	lui	a5,0x10001
    80006894:	4398                	lw	a4,0(a5)
    80006896:	2701                	sext.w	a4,a4
    80006898:	747277b7          	lui	a5,0x74727
    8000689c:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800068a0:	18f71c63          	bne	a4,a5,80006a38 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800068a4:	100017b7          	lui	a5,0x10001
    800068a8:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    800068aa:	439c                	lw	a5,0(a5)
    800068ac:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800068ae:	4709                	li	a4,2
    800068b0:	18e79463          	bne	a5,a4,80006a38 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068b4:	100017b7          	lui	a5,0x10001
    800068b8:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    800068ba:	439c                	lw	a5,0(a5)
    800068bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800068be:	16e79d63          	bne	a5,a4,80006a38 <virtio_disk_init+0x1cc>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800068c2:	100017b7          	lui	a5,0x10001
    800068c6:	47d8                	lw	a4,12(a5)
    800068c8:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800068ca:	554d47b7          	lui	a5,0x554d4
    800068ce:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800068d2:	16f71363          	bne	a4,a5,80006a38 <virtio_disk_init+0x1cc>
  *R(VIRTIO_MMIO_STATUS) = status;
    800068d6:	100017b7          	lui	a5,0x10001
    800068da:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800068de:	4705                	li	a4,1
    800068e0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800068e2:	470d                	li	a4,3
    800068e4:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800068e6:	10001737          	lui	a4,0x10001
    800068ea:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800068ec:	c7ffe737          	lui	a4,0xc7ffe
    800068f0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd660f>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800068f4:	8ef9                	and	a3,a3,a4
    800068f6:	10001737          	lui	a4,0x10001
    800068fa:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    800068fc:	472d                	li	a4,11
    800068fe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006900:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80006904:	439c                	lw	a5,0(a5)
    80006906:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    8000690a:	8ba1                	andi	a5,a5,8
    8000690c:	12078e63          	beqz	a5,80006a48 <virtio_disk_init+0x1dc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006910:	100017b7          	lui	a5,0x10001
    80006914:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006918:	100017b7          	lui	a5,0x10001
    8000691c:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    80006920:	439c                	lw	a5,0(a5)
    80006922:	2781                	sext.w	a5,a5
    80006924:	12079a63          	bnez	a5,80006a58 <virtio_disk_init+0x1ec>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006928:	100017b7          	lui	a5,0x10001
    8000692c:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80006930:	439c                	lw	a5,0(a5)
    80006932:	2781                	sext.w	a5,a5
  if(max == 0)
    80006934:	12078a63          	beqz	a5,80006a68 <virtio_disk_init+0x1fc>
  if(max < NUM)
    80006938:	471d                	li	a4,7
    8000693a:	12f77f63          	bgeu	a4,a5,80006a78 <virtio_disk_init+0x20c>
  disk.desc = kalloc();
    8000693e:	ffffa097          	auipc	ra,0xffffa
    80006942:	20a080e7          	jalr	522(ra) # 80000b48 <kalloc>
    80006946:	00021497          	auipc	s1,0x21
    8000694a:	6ca48493          	addi	s1,s1,1738 # 80028010 <disk>
    8000694e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006950:	ffffa097          	auipc	ra,0xffffa
    80006954:	1f8080e7          	jalr	504(ra) # 80000b48 <kalloc>
    80006958:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000695a:	ffffa097          	auipc	ra,0xffffa
    8000695e:	1ee080e7          	jalr	494(ra) # 80000b48 <kalloc>
    80006962:	87aa                	mv	a5,a0
    80006964:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006966:	6088                	ld	a0,0(s1)
    80006968:	12050063          	beqz	a0,80006a88 <virtio_disk_init+0x21c>
    8000696c:	00021717          	auipc	a4,0x21
    80006970:	6ac73703          	ld	a4,1708(a4) # 80028018 <disk+0x8>
    80006974:	10070a63          	beqz	a4,80006a88 <virtio_disk_init+0x21c>
    80006978:	10078863          	beqz	a5,80006a88 <virtio_disk_init+0x21c>
  memset(disk.desc, 0, PGSIZE);
    8000697c:	6605                	lui	a2,0x1
    8000697e:	4581                	li	a1,0
    80006980:	ffffa097          	auipc	ra,0xffffa
    80006984:	3b4080e7          	jalr	948(ra) # 80000d34 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006988:	00021497          	auipc	s1,0x21
    8000698c:	68848493          	addi	s1,s1,1672 # 80028010 <disk>
    80006990:	6605                	lui	a2,0x1
    80006992:	4581                	li	a1,0
    80006994:	6488                	ld	a0,8(s1)
    80006996:	ffffa097          	auipc	ra,0xffffa
    8000699a:	39e080e7          	jalr	926(ra) # 80000d34 <memset>
  memset(disk.used, 0, PGSIZE);
    8000699e:	6605                	lui	a2,0x1
    800069a0:	4581                	li	a1,0
    800069a2:	6888                	ld	a0,16(s1)
    800069a4:	ffffa097          	auipc	ra,0xffffa
    800069a8:	390080e7          	jalr	912(ra) # 80000d34 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800069ac:	100017b7          	lui	a5,0x10001
    800069b0:	4721                	li	a4,8
    800069b2:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800069b4:	4098                	lw	a4,0(s1)
    800069b6:	100017b7          	lui	a5,0x10001
    800069ba:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800069be:	40d8                	lw	a4,4(s1)
    800069c0:	100017b7          	lui	a5,0x10001
    800069c4:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800069c8:	649c                	ld	a5,8(s1)
    800069ca:	0007869b          	sext.w	a3,a5
    800069ce:	10001737          	lui	a4,0x10001
    800069d2:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800069d6:	9781                	srai	a5,a5,0x20
    800069d8:	10001737          	lui	a4,0x10001
    800069dc:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800069e0:	689c                	ld	a5,16(s1)
    800069e2:	0007869b          	sext.w	a3,a5
    800069e6:	10001737          	lui	a4,0x10001
    800069ea:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800069ee:	9781                	srai	a5,a5,0x20
    800069f0:	10001737          	lui	a4,0x10001
    800069f4:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800069f8:	10001737          	lui	a4,0x10001
    800069fc:	4785                	li	a5,1
    800069fe:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    80006a00:	00f48c23          	sb	a5,24(s1)
    80006a04:	00f48ca3          	sb	a5,25(s1)
    80006a08:	00f48d23          	sb	a5,26(s1)
    80006a0c:	00f48da3          	sb	a5,27(s1)
    80006a10:	00f48e23          	sb	a5,28(s1)
    80006a14:	00f48ea3          	sb	a5,29(s1)
    80006a18:	00f48f23          	sb	a5,30(s1)
    80006a1c:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006a20:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a24:	100017b7          	lui	a5,0x10001
    80006a28:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    80006a2c:	60e2                	ld	ra,24(sp)
    80006a2e:	6442                	ld	s0,16(sp)
    80006a30:	64a2                	ld	s1,8(sp)
    80006a32:	6902                	ld	s2,0(sp)
    80006a34:	6105                	addi	sp,sp,32
    80006a36:	8082                	ret
    panic("could not find virtio disk");
    80006a38:	00002517          	auipc	a0,0x2
    80006a3c:	c5850513          	addi	a0,a0,-936 # 80008690 <etext+0x690>
    80006a40:	ffffa097          	auipc	ra,0xffffa
    80006a44:	b20080e7          	jalr	-1248(ra) # 80000560 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006a48:	00002517          	auipc	a0,0x2
    80006a4c:	c6850513          	addi	a0,a0,-920 # 800086b0 <etext+0x6b0>
    80006a50:	ffffa097          	auipc	ra,0xffffa
    80006a54:	b10080e7          	jalr	-1264(ra) # 80000560 <panic>
    panic("virtio disk should not be ready");
    80006a58:	00002517          	auipc	a0,0x2
    80006a5c:	c7850513          	addi	a0,a0,-904 # 800086d0 <etext+0x6d0>
    80006a60:	ffffa097          	auipc	ra,0xffffa
    80006a64:	b00080e7          	jalr	-1280(ra) # 80000560 <panic>
    panic("virtio disk has no queue 0");
    80006a68:	00002517          	auipc	a0,0x2
    80006a6c:	c8850513          	addi	a0,a0,-888 # 800086f0 <etext+0x6f0>
    80006a70:	ffffa097          	auipc	ra,0xffffa
    80006a74:	af0080e7          	jalr	-1296(ra) # 80000560 <panic>
    panic("virtio disk max queue too short");
    80006a78:	00002517          	auipc	a0,0x2
    80006a7c:	c9850513          	addi	a0,a0,-872 # 80008710 <etext+0x710>
    80006a80:	ffffa097          	auipc	ra,0xffffa
    80006a84:	ae0080e7          	jalr	-1312(ra) # 80000560 <panic>
    panic("virtio disk kalloc");
    80006a88:	00002517          	auipc	a0,0x2
    80006a8c:	ca850513          	addi	a0,a0,-856 # 80008730 <etext+0x730>
    80006a90:	ffffa097          	auipc	ra,0xffffa
    80006a94:	ad0080e7          	jalr	-1328(ra) # 80000560 <panic>

0000000080006a98 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006a98:	7159                	addi	sp,sp,-112
    80006a9a:	f486                	sd	ra,104(sp)
    80006a9c:	f0a2                	sd	s0,96(sp)
    80006a9e:	eca6                	sd	s1,88(sp)
    80006aa0:	e8ca                	sd	s2,80(sp)
    80006aa2:	e4ce                	sd	s3,72(sp)
    80006aa4:	e0d2                	sd	s4,64(sp)
    80006aa6:	fc56                	sd	s5,56(sp)
    80006aa8:	f85a                	sd	s6,48(sp)
    80006aaa:	f45e                	sd	s7,40(sp)
    80006aac:	f062                	sd	s8,32(sp)
    80006aae:	ec66                	sd	s9,24(sp)
    80006ab0:	1880                	addi	s0,sp,112
    80006ab2:	8a2a                	mv	s4,a0
    80006ab4:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006ab6:	00c52c83          	lw	s9,12(a0)
    80006aba:	001c9c9b          	slliw	s9,s9,0x1
    80006abe:	1c82                	slli	s9,s9,0x20
    80006ac0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006ac4:	00021517          	auipc	a0,0x21
    80006ac8:	67450513          	addi	a0,a0,1652 # 80028138 <disk+0x128>
    80006acc:	ffffa097          	auipc	ra,0xffffa
    80006ad0:	16c080e7          	jalr	364(ra) # 80000c38 <acquire>
  for(int i = 0; i < 3; i++){
    80006ad4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006ad6:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006ad8:	00021b17          	auipc	s6,0x21
    80006adc:	538b0b13          	addi	s6,s6,1336 # 80028010 <disk>
  for(int i = 0; i < 3; i++){
    80006ae0:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006ae2:	00021c17          	auipc	s8,0x21
    80006ae6:	656c0c13          	addi	s8,s8,1622 # 80028138 <disk+0x128>
    80006aea:	a0ad                	j	80006b54 <virtio_disk_rw+0xbc>
      disk.free[i] = 0;
    80006aec:	00fb0733          	add	a4,s6,a5
    80006af0:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80006af4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006af6:	0207c563          	bltz	a5,80006b20 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006afa:	2905                	addiw	s2,s2,1
    80006afc:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006afe:	05590f63          	beq	s2,s5,80006b5c <virtio_disk_rw+0xc4>
    idx[i] = alloc_desc();
    80006b02:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006b04:	00021717          	auipc	a4,0x21
    80006b08:	50c70713          	addi	a4,a4,1292 # 80028010 <disk>
    80006b0c:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006b0e:	01874683          	lbu	a3,24(a4)
    80006b12:	fee9                	bnez	a3,80006aec <virtio_disk_rw+0x54>
  for(int i = 0; i < NUM; i++){
    80006b14:	2785                	addiw	a5,a5,1
    80006b16:	0705                	addi	a4,a4,1
    80006b18:	fe979be3          	bne	a5,s1,80006b0e <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006b1c:	57fd                	li	a5,-1
    80006b1e:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006b20:	03205163          	blez	s2,80006b42 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006b24:	f9042503          	lw	a0,-112(s0)
    80006b28:	00000097          	auipc	ra,0x0
    80006b2c:	cc2080e7          	jalr	-830(ra) # 800067ea <free_desc>
      for(int j = 0; j < i; j++)
    80006b30:	4785                	li	a5,1
    80006b32:	0127d863          	bge	a5,s2,80006b42 <virtio_disk_rw+0xaa>
        free_desc(idx[j]);
    80006b36:	f9442503          	lw	a0,-108(s0)
    80006b3a:	00000097          	auipc	ra,0x0
    80006b3e:	cb0080e7          	jalr	-848(ra) # 800067ea <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006b42:	85e2                	mv	a1,s8
    80006b44:	00021517          	auipc	a0,0x21
    80006b48:	4e450513          	addi	a0,a0,1252 # 80028028 <disk+0x18>
    80006b4c:	ffffc097          	auipc	ra,0xffffc
    80006b50:	a0a080e7          	jalr	-1526(ra) # 80002556 <sleep>
  for(int i = 0; i < 3; i++){
    80006b54:	f9040613          	addi	a2,s0,-112
    80006b58:	894e                	mv	s2,s3
    80006b5a:	b765                	j	80006b02 <virtio_disk_rw+0x6a>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b5c:	f9042503          	lw	a0,-112(s0)
    80006b60:	00451693          	slli	a3,a0,0x4

  if(write)
    80006b64:	00021797          	auipc	a5,0x21
    80006b68:	4ac78793          	addi	a5,a5,1196 # 80028010 <disk>
    80006b6c:	00a50713          	addi	a4,a0,10
    80006b70:	0712                	slli	a4,a4,0x4
    80006b72:	973e                	add	a4,a4,a5
    80006b74:	01703633          	snez	a2,s7
    80006b78:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006b7a:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006b7e:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b82:	6398                	ld	a4,0(a5)
    80006b84:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006b86:	0a868613          	addi	a2,a3,168
    80006b8a:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006b8c:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006b8e:	6390                	ld	a2,0(a5)
    80006b90:	00d605b3          	add	a1,a2,a3
    80006b94:	4741                	li	a4,16
    80006b96:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006b98:	4805                	li	a6,1
    80006b9a:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80006b9e:	f9442703          	lw	a4,-108(s0)
    80006ba2:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006ba6:	0712                	slli	a4,a4,0x4
    80006ba8:	963a                	add	a2,a2,a4
    80006baa:	058a0593          	addi	a1,s4,88
    80006bae:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006bb0:	0007b883          	ld	a7,0(a5)
    80006bb4:	9746                	add	a4,a4,a7
    80006bb6:	40000613          	li	a2,1024
    80006bba:	c710                	sw	a2,8(a4)
  if(write)
    80006bbc:	001bb613          	seqz	a2,s7
    80006bc0:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006bc4:	00166613          	ori	a2,a2,1
    80006bc8:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006bcc:	f9842583          	lw	a1,-104(s0)
    80006bd0:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006bd4:	00250613          	addi	a2,a0,2
    80006bd8:	0612                	slli	a2,a2,0x4
    80006bda:	963e                	add	a2,a2,a5
    80006bdc:	577d                	li	a4,-1
    80006bde:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006be2:	0592                	slli	a1,a1,0x4
    80006be4:	98ae                	add	a7,a7,a1
    80006be6:	03068713          	addi	a4,a3,48
    80006bea:	973e                	add	a4,a4,a5
    80006bec:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80006bf0:	6398                	ld	a4,0(a5)
    80006bf2:	972e                	add	a4,a4,a1
    80006bf4:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006bf8:	4689                	li	a3,2
    80006bfa:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80006bfe:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006c02:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80006c06:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006c0a:	6794                	ld	a3,8(a5)
    80006c0c:	0026d703          	lhu	a4,2(a3)
    80006c10:	8b1d                	andi	a4,a4,7
    80006c12:	0706                	slli	a4,a4,0x1
    80006c14:	96ba                	add	a3,a3,a4
    80006c16:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006c1a:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006c1e:	6798                	ld	a4,8(a5)
    80006c20:	00275783          	lhu	a5,2(a4)
    80006c24:	2785                	addiw	a5,a5,1
    80006c26:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006c2a:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006c2e:	100017b7          	lui	a5,0x10001
    80006c32:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006c36:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006c3a:	00021917          	auipc	s2,0x21
    80006c3e:	4fe90913          	addi	s2,s2,1278 # 80028138 <disk+0x128>
  while(b->disk == 1) {
    80006c42:	4485                	li	s1,1
    80006c44:	01079c63          	bne	a5,a6,80006c5c <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006c48:	85ca                	mv	a1,s2
    80006c4a:	8552                	mv	a0,s4
    80006c4c:	ffffc097          	auipc	ra,0xffffc
    80006c50:	90a080e7          	jalr	-1782(ra) # 80002556 <sleep>
  while(b->disk == 1) {
    80006c54:	004a2783          	lw	a5,4(s4)
    80006c58:	fe9788e3          	beq	a5,s1,80006c48 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006c5c:	f9042903          	lw	s2,-112(s0)
    80006c60:	00290713          	addi	a4,s2,2
    80006c64:	0712                	slli	a4,a4,0x4
    80006c66:	00021797          	auipc	a5,0x21
    80006c6a:	3aa78793          	addi	a5,a5,938 # 80028010 <disk>
    80006c6e:	97ba                	add	a5,a5,a4
    80006c70:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006c74:	00021997          	auipc	s3,0x21
    80006c78:	39c98993          	addi	s3,s3,924 # 80028010 <disk>
    80006c7c:	00491713          	slli	a4,s2,0x4
    80006c80:	0009b783          	ld	a5,0(s3)
    80006c84:	97ba                	add	a5,a5,a4
    80006c86:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006c8a:	854a                	mv	a0,s2
    80006c8c:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006c90:	00000097          	auipc	ra,0x0
    80006c94:	b5a080e7          	jalr	-1190(ra) # 800067ea <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006c98:	8885                	andi	s1,s1,1
    80006c9a:	f0ed                	bnez	s1,80006c7c <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006c9c:	00021517          	auipc	a0,0x21
    80006ca0:	49c50513          	addi	a0,a0,1180 # 80028138 <disk+0x128>
    80006ca4:	ffffa097          	auipc	ra,0xffffa
    80006ca8:	048080e7          	jalr	72(ra) # 80000cec <release>
}
    80006cac:	70a6                	ld	ra,104(sp)
    80006cae:	7406                	ld	s0,96(sp)
    80006cb0:	64e6                	ld	s1,88(sp)
    80006cb2:	6946                	ld	s2,80(sp)
    80006cb4:	69a6                	ld	s3,72(sp)
    80006cb6:	6a06                	ld	s4,64(sp)
    80006cb8:	7ae2                	ld	s5,56(sp)
    80006cba:	7b42                	ld	s6,48(sp)
    80006cbc:	7ba2                	ld	s7,40(sp)
    80006cbe:	7c02                	ld	s8,32(sp)
    80006cc0:	6ce2                	ld	s9,24(sp)
    80006cc2:	6165                	addi	sp,sp,112
    80006cc4:	8082                	ret

0000000080006cc6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006cc6:	1101                	addi	sp,sp,-32
    80006cc8:	ec06                	sd	ra,24(sp)
    80006cca:	e822                	sd	s0,16(sp)
    80006ccc:	e426                	sd	s1,8(sp)
    80006cce:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006cd0:	00021497          	auipc	s1,0x21
    80006cd4:	34048493          	addi	s1,s1,832 # 80028010 <disk>
    80006cd8:	00021517          	auipc	a0,0x21
    80006cdc:	46050513          	addi	a0,a0,1120 # 80028138 <disk+0x128>
    80006ce0:	ffffa097          	auipc	ra,0xffffa
    80006ce4:	f58080e7          	jalr	-168(ra) # 80000c38 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006ce8:	100017b7          	lui	a5,0x10001
    80006cec:	53b8                	lw	a4,96(a5)
    80006cee:	8b0d                	andi	a4,a4,3
    80006cf0:	100017b7          	lui	a5,0x10001
    80006cf4:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80006cf6:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006cfa:	689c                	ld	a5,16(s1)
    80006cfc:	0204d703          	lhu	a4,32(s1)
    80006d00:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80006d04:	04f70863          	beq	a4,a5,80006d54 <virtio_disk_intr+0x8e>
    __sync_synchronize();
    80006d08:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006d0c:	6898                	ld	a4,16(s1)
    80006d0e:	0204d783          	lhu	a5,32(s1)
    80006d12:	8b9d                	andi	a5,a5,7
    80006d14:	078e                	slli	a5,a5,0x3
    80006d16:	97ba                	add	a5,a5,a4
    80006d18:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006d1a:	00278713          	addi	a4,a5,2
    80006d1e:	0712                	slli	a4,a4,0x4
    80006d20:	9726                	add	a4,a4,s1
    80006d22:	01074703          	lbu	a4,16(a4)
    80006d26:	e721                	bnez	a4,80006d6e <virtio_disk_intr+0xa8>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006d28:	0789                	addi	a5,a5,2
    80006d2a:	0792                	slli	a5,a5,0x4
    80006d2c:	97a6                	add	a5,a5,s1
    80006d2e:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006d30:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006d34:	ffffc097          	auipc	ra,0xffffc
    80006d38:	8a0080e7          	jalr	-1888(ra) # 800025d4 <wakeup>

    disk.used_idx += 1;
    80006d3c:	0204d783          	lhu	a5,32(s1)
    80006d40:	2785                	addiw	a5,a5,1
    80006d42:	17c2                	slli	a5,a5,0x30
    80006d44:	93c1                	srli	a5,a5,0x30
    80006d46:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006d4a:	6898                	ld	a4,16(s1)
    80006d4c:	00275703          	lhu	a4,2(a4)
    80006d50:	faf71ce3          	bne	a4,a5,80006d08 <virtio_disk_intr+0x42>
  }

  release(&disk.vdisk_lock);
    80006d54:	00021517          	auipc	a0,0x21
    80006d58:	3e450513          	addi	a0,a0,996 # 80028138 <disk+0x128>
    80006d5c:	ffffa097          	auipc	ra,0xffffa
    80006d60:	f90080e7          	jalr	-112(ra) # 80000cec <release>
}
    80006d64:	60e2                	ld	ra,24(sp)
    80006d66:	6442                	ld	s0,16(sp)
    80006d68:	64a2                	ld	s1,8(sp)
    80006d6a:	6105                	addi	sp,sp,32
    80006d6c:	8082                	ret
      panic("virtio_disk_intr status");
    80006d6e:	00002517          	auipc	a0,0x2
    80006d72:	9da50513          	addi	a0,a0,-1574 # 80008748 <etext+0x748>
    80006d76:	ffff9097          	auipc	ra,0xffff9
    80006d7a:	7ea080e7          	jalr	2026(ra) # 80000560 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
