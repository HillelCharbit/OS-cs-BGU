
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a2010113          	addi	sp,sp,-1504 # 80008a20 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	88e70713          	addi	a4,a4,-1906 # 800088e0 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	e4c78793          	addi	a5,a5,-436 # 80005eb0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdcaaf>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	5a8080e7          	jalr	1448(ra) # 800026d4 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	89450513          	addi	a0,a0,-1900 # 80010a20 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	88448493          	addi	s1,s1,-1916 # 80010a20 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	91290913          	addi	s2,s2,-1774 # 80010ab8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	146080e7          	jalr	326(ra) # 80002312 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	e90080e7          	jalr	-368(ra) # 8000206a <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	468080e7          	jalr	1128(ra) # 8000267e <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00010517          	auipc	a0,0x10
    8000022e:	7f650513          	addi	a0,a0,2038 # 80010a20 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00010517          	auipc	a0,0x10
    80000244:	7e050513          	addi	a0,a0,2016 # 80010a20 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	84f72023          	sw	a5,-1984(a4) # 80010ab8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00010517          	auipc	a0,0x10
    800002d6:	74e50513          	addi	a0,a0,1870 # 80010a20 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	432080e7          	jalr	1074(ra) # 8000272a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00010517          	auipc	a0,0x10
    80000304:	72050513          	addi	a0,a0,1824 # 80010a20 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00010717          	auipc	a4,0x10
    80000328:	6fc70713          	addi	a4,a4,1788 # 80010a20 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00010797          	auipc	a5,0x10
    80000352:	6d278793          	addi	a5,a5,1746 # 80010a20 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00010797          	auipc	a5,0x10
    80000380:	73c7a783          	lw	a5,1852(a5) # 80010ab8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00010717          	auipc	a4,0x10
    80000394:	69070713          	addi	a4,a4,1680 # 80010a20 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00010497          	auipc	s1,0x10
    800003a4:	68048493          	addi	s1,s1,1664 # 80010a20 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00010717          	auipc	a4,0x10
    800003e0:	64470713          	addi	a4,a4,1604 # 80010a20 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00010717          	auipc	a4,0x10
    800003f6:	6cf72723          	sw	a5,1742(a4) # 80010ac0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00010797          	auipc	a5,0x10
    8000041c:	60878793          	addi	a5,a5,1544 # 80010a20 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00010797          	auipc	a5,0x10
    80000440:	68c7a023          	sw	a2,1664(a5) # 80010abc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00010517          	auipc	a0,0x10
    80000448:	67450513          	addi	a0,a0,1652 # 80010ab8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	c82080e7          	jalr	-894(ra) # 800020ce <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	5ba50513          	addi	a0,a0,1466 # 80010a20 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00020797          	auipc	a5,0x20
    80000482:	73a78793          	addi	a5,a5,1850 # 80020bb8 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	5807a823          	sw	zero,1424(a5) # 80010ae0 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	30f72e23          	sw	a5,796(a4) # 800088a0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	520dad83          	lw	s11,1312(s11) # 80010ae0 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	4ca50513          	addi	a0,a0,1226 # 80010ac8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	36650513          	addi	a0,a0,870 # 80010ac8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	34a48493          	addi	s1,s1,842 # 80010ac8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	30a50513          	addi	a0,a0,778 # 80010ae8 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	0967a783          	lw	a5,150(a5) # 800088a0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	06273703          	ld	a4,98(a4) # 800088a8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	0627b783          	ld	a5,98(a5) # 800088b0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	278a0a13          	addi	s4,s4,632 # 80010ae8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	03048493          	addi	s1,s1,48 # 800088a8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	03098993          	addi	s3,s3,48 # 800088b0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	828080e7          	jalr	-2008(ra) # 800020ce <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	20650513          	addi	a0,a0,518 # 80010ae8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fae7a783          	lw	a5,-82(a5) # 800088a0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	fb47b783          	ld	a5,-76(a5) # 800088b0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	fa473703          	ld	a4,-92(a4) # 800088a8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	1d8a0a13          	addi	s4,s4,472 # 80010ae8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	f9048493          	addi	s1,s1,-112 # 800088a8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	f9090913          	addi	s2,s2,-112 # 800088b0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	73a080e7          	jalr	1850(ra) # 8000206a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	1a248493          	addi	s1,s1,418 # 80010ae8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	f4f73b23          	sd	a5,-170(a4) # 800088b0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	11848493          	addi	s1,s1,280 # 80010ae8 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	00021797          	auipc	a5,0x21
    80000a16:	33e78793          	addi	a5,a5,830 # 80021d50 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	0ee90913          	addi	s2,s2,238 # 80010b20 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	05250513          	addi	a0,a0,82 # 80010b20 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00021517          	auipc	a0,0x21
    80000ae6:	26e50513          	addi	a0,a0,622 # 80021d50 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	01c48493          	addi	s1,s1,28 # 80010b20 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	00450513          	addi	a0,a0,4 # 80010b20 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	fd850513          	addi	a0,a0,-40 # 80010b20 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	a1470713          	addi	a4,a4,-1516 # 800088b8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	990080e7          	jalr	-1648(ra) # 8000286a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	00e080e7          	jalr	14(ra) # 80005ef0 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	fce080e7          	jalr	-50(ra) # 80001eb8 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00002097          	auipc	ra,0x2
    80000f56:	8f0080e7          	jalr	-1808(ra) # 80002842 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	910080e7          	jalr	-1776(ra) # 8000286a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f78080e7          	jalr	-136(ra) # 80005eda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	f86080e7          	jalr	-122(ra) # 80005ef0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	13a080e7          	jalr	314(ra) # 800030ac <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	7de080e7          	jalr	2014(ra) # 80003758 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	77c080e7          	jalr	1916(ra) # 800046fe <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	06e080e7          	jalr	110(ra) # 80005ff8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	90f72c23          	sw	a5,-1768(a4) # 800088b8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	90c7b783          	ld	a5,-1780(a5) # 800088c0 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00007797          	auipc	a5,0x7
    80001274:	64a7b823          	sd	a0,1616(a5) # 800088c0 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	0000f497          	auipc	s1,0xf
    8000186a:	70a48493          	addi	s1,s1,1802 # 80010f70 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	0f0a0a13          	addi	s4,s4,240 # 80016970 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	858d                	srai	a1,a1,0x3
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	16848493          	addi	s1,s1,360
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	23e50513          	addi	a0,a0,574 # 80010b40 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	23e50513          	addi	a0,a0,574 # 80010b58 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	0000f497          	auipc	s1,0xf
    8000192e:	64648493          	addi	s1,s1,1606 # 80010f70 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	02498993          	addi	s3,s3,36 # 80016970 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	878d                	srai	a5,a5,0x3
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	16848493          	addi	s1,s1,360
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	1ba50513          	addi	a0,a0,442 # 80010b70 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	16270713          	addi	a4,a4,354 # 80010b40 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e3a7a783          	lw	a5,-454(a5) # 80008850 <first.1704>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	e62080e7          	jalr	-414(ra) # 80002882 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e207a023          	sw	zero,-480(a5) # 80008850 <first.1704>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	c9e080e7          	jalr	-866(ra) # 800036d8 <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	0f090913          	addi	s2,s2,240 # 80010b40 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	df278793          	addi	a5,a5,-526 # 80008854 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	39448493          	addi	s1,s1,916 # 80010f70 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	d8c90913          	addi	s2,s2,-628 # 80016970 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	16848493          	addi	s1,s1,360
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a889                	j	80001c60 <allocproc+0x90>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	edc080e7          	jalr	-292(ra) # 80000afa <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	c131                	beqz	a0,80001c6e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3a:	c531                	beqz	a0,80001c86 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
}
    80001c60:	8526                	mv	a0,s1
    80001c62:	60e2                	ld	ra,24(sp)
    80001c64:	6442                	ld	s0,16(sp)
    80001c66:	64a2                	ld	s1,8(sp)
    80001c68:	6902                	ld	s2,0(sp)
    80001c6a:	6105                	addi	sp,sp,32
    80001c6c:	8082                	ret
    freeproc(p);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	f08080e7          	jalr	-248(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	024080e7          	jalr	36(ra) # 80000c9e <release>
    return 0;
    80001c82:	84ca                	mv	s1,s2
    80001c84:	bff1                	j	80001c60 <allocproc+0x90>
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	ef0080e7          	jalr	-272(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	00c080e7          	jalr	12(ra) # 80000c9e <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	b7d1                	j	80001c60 <allocproc+0x90>

0000000080001c9e <userinit>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f28080e7          	jalr	-216(ra) # 80001bd0 <allocproc>
    80001cb0:	84aa                	mv	s1,a0
  initproc = p;
    80001cb2:	00007797          	auipc	a5,0x7
    80001cb6:	c0a7bb23          	sd	a0,-1002(a5) # 800088c8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	ba258593          	addi	a1,a1,-1118 # 80008860 <initcode>
    80001cc6:	6928                	ld	a0,80(a0)
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	6aa080e7          	jalr	1706(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cd0:	6785                	lui	a5,0x1
    80001cd2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cde:	4641                	li	a2,16
    80001ce0:	00006597          	auipc	a1,0x6
    80001ce4:	52058593          	addi	a1,a1,1312 # 80008200 <digits+0x1c0>
    80001ce8:	15848513          	addi	a0,s1,344
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	14c080e7          	jalr	332(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001cf4:	00006517          	auipc	a0,0x6
    80001cf8:	51c50513          	addi	a0,a0,1308 # 80008210 <digits+0x1d0>
    80001cfc:	00002097          	auipc	ra,0x2
    80001d00:	3fe080e7          	jalr	1022(ra) # 800040fa <namei>
    80001d04:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d08:	478d                	li	a5,3
    80001d0a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f90080e7          	jalr	-112(ra) # 80000c9e <release>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <growproc>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	c98080e7          	jalr	-872(ra) # 800019c6 <myproc>
    80001d36:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d38:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d3a:	01204c63          	bgtz	s2,80001d52 <growproc+0x32>
  } else if(n < 0){
    80001d3e:	02094663          	bltz	s2,80001d6a <growproc+0x4a>
  p->sz = sz;
    80001d42:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d44:	4501                	li	a0,0
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d52:	4691                	li	a3,4
    80001d54:	00b90633          	add	a2,s2,a1
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d2080e7          	jalr	1746(ra) # 8000142c <uvmalloc>
    80001d62:	85aa                	mv	a1,a0
    80001d64:	fd79                	bnez	a0,80001d42 <growproc+0x22>
      return -1;
    80001d66:	557d                	li	a0,-1
    80001d68:	bff9                	j	80001d46 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	674080e7          	jalr	1652(ra) # 800013e4 <uvmdealloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	b7e1                	j	80001d42 <growproc+0x22>

0000000080001d7c <fork>:
{
    80001d7c:	7179                	addi	sp,sp,-48
    80001d7e:	f406                	sd	ra,40(sp)
    80001d80:	f022                	sd	s0,32(sp)
    80001d82:	ec26                	sd	s1,24(sp)
    80001d84:	e84a                	sd	s2,16(sp)
    80001d86:	e44e                	sd	s3,8(sp)
    80001d88:	e052                	sd	s4,0(sp)
    80001d8a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c3a080e7          	jalr	-966(ra) # 800019c6 <myproc>
    80001d94:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e3a080e7          	jalr	-454(ra) # 80001bd0 <allocproc>
    80001d9e:	10050b63          	beqz	a0,80001eb4 <fork+0x138>
    80001da2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da4:	04893603          	ld	a2,72(s2)
    80001da8:	692c                	ld	a1,80(a0)
    80001daa:	05093503          	ld	a0,80(s2)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	7d2080e7          	jalr	2002(ra) # 80001580 <uvmcopy>
    80001db6:	04054663          	bltz	a0,80001e02 <fork+0x86>
  np->sz = p->sz;
    80001dba:	04893783          	ld	a5,72(s2)
    80001dbe:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc2:	05893683          	ld	a3,88(s2)
    80001dc6:	87b6                	mv	a5,a3
    80001dc8:	0589b703          	ld	a4,88(s3)
    80001dcc:	12068693          	addi	a3,a3,288
    80001dd0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd4:	6788                	ld	a0,8(a5)
    80001dd6:	6b8c                	ld	a1,16(a5)
    80001dd8:	6f90                	ld	a2,24(a5)
    80001dda:	01073023          	sd	a6,0(a4)
    80001dde:	e708                	sd	a0,8(a4)
    80001de0:	eb0c                	sd	a1,16(a4)
    80001de2:	ef10                	sd	a2,24(a4)
    80001de4:	02078793          	addi	a5,a5,32
    80001de8:	02070713          	addi	a4,a4,32
    80001dec:	fed792e3          	bne	a5,a3,80001dd0 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df0:	0589b783          	ld	a5,88(s3)
    80001df4:	0607b823          	sd	zero,112(a5)
    80001df8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfc:	15000a13          	li	s4,336
    80001e00:	a03d                	j	80001e2e <fork+0xb2>
    freeproc(np);
    80001e02:	854e                	mv	a0,s3
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d74080e7          	jalr	-652(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e90080e7          	jalr	-368(ra) # 80000c9e <release>
    return -1;
    80001e16:	5a7d                	li	s4,-1
    80001e18:	a069                	j	80001ea2 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1a:	00003097          	auipc	ra,0x3
    80001e1e:	976080e7          	jalr	-1674(ra) # 80004790 <filedup>
    80001e22:	009987b3          	add	a5,s3,s1
    80001e26:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e28:	04a1                	addi	s1,s1,8
    80001e2a:	01448763          	beq	s1,s4,80001e38 <fork+0xbc>
    if(p->ofile[i])
    80001e2e:	009907b3          	add	a5,s2,s1
    80001e32:	6388                	ld	a0,0(a5)
    80001e34:	f17d                	bnez	a0,80001e1a <fork+0x9e>
    80001e36:	bfcd                	j	80001e28 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e38:	15093503          	ld	a0,336(s2)
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	ada080e7          	jalr	-1318(ra) # 80003916 <idup>
    80001e44:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e48:	4641                	li	a2,16
    80001e4a:	15890593          	addi	a1,s2,344
    80001e4e:	15898513          	addi	a0,s3,344
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	fe6080e7          	jalr	-26(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e5a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e5e:	854e                	mv	a0,s3
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e3e080e7          	jalr	-450(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e68:	0000f497          	auipc	s1,0xf
    80001e6c:	cf048493          	addi	s1,s1,-784 # 80010b58 <wait_lock>
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d78080e7          	jalr	-648(ra) # 80000bea <acquire>
  np->parent = p;
    80001e7a:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e1e080e7          	jalr	-482(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d60080e7          	jalr	-672(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001e92:	478d                	li	a5,3
    80001e94:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e04080e7          	jalr	-508(ra) # 80000c9e <release>
}
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	70a2                	ld	ra,40(sp)
    80001ea6:	7402                	ld	s0,32(sp)
    80001ea8:	64e2                	ld	s1,24(sp)
    80001eaa:	6942                	ld	s2,16(sp)
    80001eac:	69a2                	ld	s3,8(sp)
    80001eae:	6a02                	ld	s4,0(sp)
    80001eb0:	6145                	addi	sp,sp,48
    80001eb2:	8082                	ret
    return -1;
    80001eb4:	5a7d                	li	s4,-1
    80001eb6:	b7f5                	j	80001ea2 <fork+0x126>

0000000080001eb8 <scheduler>:
{
    80001eb8:	7139                	addi	sp,sp,-64
    80001eba:	fc06                	sd	ra,56(sp)
    80001ebc:	f822                	sd	s0,48(sp)
    80001ebe:	f426                	sd	s1,40(sp)
    80001ec0:	f04a                	sd	s2,32(sp)
    80001ec2:	ec4e                	sd	s3,24(sp)
    80001ec4:	e852                	sd	s4,16(sp)
    80001ec6:	e456                	sd	s5,8(sp)
    80001ec8:	e05a                	sd	s6,0(sp)
    80001eca:	0080                	addi	s0,sp,64
    80001ecc:	8792                	mv	a5,tp
  int id = r_tp();
    80001ece:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ed0:	00779a93          	slli	s5,a5,0x7
    80001ed4:	0000f717          	auipc	a4,0xf
    80001ed8:	c6c70713          	addi	a4,a4,-916 # 80010b40 <pid_lock>
    80001edc:	9756                	add	a4,a4,s5
    80001ede:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ee2:	0000f717          	auipc	a4,0xf
    80001ee6:	c9670713          	addi	a4,a4,-874 # 80010b78 <cpus+0x8>
    80001eea:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001eec:	498d                	li	s3,3
        p->state = RUNNING;
    80001eee:	4b11                	li	s6,4
        c->proc = p;
    80001ef0:	079e                	slli	a5,a5,0x7
    80001ef2:	0000fa17          	auipc	s4,0xf
    80001ef6:	c4ea0a13          	addi	s4,s4,-946 # 80010b40 <pid_lock>
    80001efa:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001efc:	00015917          	auipc	s2,0x15
    80001f00:	a7490913          	addi	s2,s2,-1420 # 80016970 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f0c:	10079073          	csrw	sstatus,a5
    80001f10:	0000f497          	auipc	s1,0xf
    80001f14:	06048493          	addi	s1,s1,96 # 80010f70 <proc>
    80001f18:	a03d                	j	80001f46 <scheduler+0x8e>
        p->state = RUNNING;
    80001f1a:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f1e:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f22:	06048593          	addi	a1,s1,96
    80001f26:	8556                	mv	a0,s5
    80001f28:	00001097          	auipc	ra,0x1
    80001f2c:	8b0080e7          	jalr	-1872(ra) # 800027d8 <swtch>
        c->proc = 0;
    80001f30:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    80001f34:	8526                	mv	a0,s1
    80001f36:	fffff097          	auipc	ra,0xfffff
    80001f3a:	d68080e7          	jalr	-664(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f3e:	16848493          	addi	s1,s1,360
    80001f42:	fd2481e3          	beq	s1,s2,80001f04 <scheduler+0x4c>
      acquire(&p->lock);
    80001f46:	8526                	mv	a0,s1
    80001f48:	fffff097          	auipc	ra,0xfffff
    80001f4c:	ca2080e7          	jalr	-862(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001f50:	4c9c                	lw	a5,24(s1)
    80001f52:	ff3791e3          	bne	a5,s3,80001f34 <scheduler+0x7c>
    80001f56:	b7d1                	j	80001f1a <scheduler+0x62>

0000000080001f58 <sched>:
{
    80001f58:	7179                	addi	sp,sp,-48
    80001f5a:	f406                	sd	ra,40(sp)
    80001f5c:	f022                	sd	s0,32(sp)
    80001f5e:	ec26                	sd	s1,24(sp)
    80001f60:	e84a                	sd	s2,16(sp)
    80001f62:	e44e                	sd	s3,8(sp)
    80001f64:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	a60080e7          	jalr	-1440(ra) # 800019c6 <myproc>
    80001f6e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	c00080e7          	jalr	-1024(ra) # 80000b70 <holding>
    80001f78:	c93d                	beqz	a0,80001fee <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f7a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f7c:	2781                	sext.w	a5,a5
    80001f7e:	079e                	slli	a5,a5,0x7
    80001f80:	0000f717          	auipc	a4,0xf
    80001f84:	bc070713          	addi	a4,a4,-1088 # 80010b40 <pid_lock>
    80001f88:	97ba                	add	a5,a5,a4
    80001f8a:	0a87a703          	lw	a4,168(a5)
    80001f8e:	4785                	li	a5,1
    80001f90:	06f71763          	bne	a4,a5,80001ffe <sched+0xa6>
  if(p->state == RUNNING)
    80001f94:	4c98                	lw	a4,24(s1)
    80001f96:	4791                	li	a5,4
    80001f98:	06f70b63          	beq	a4,a5,8000200e <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f9c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fa0:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fa2:	efb5                	bnez	a5,8000201e <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fa4:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fa6:	0000f917          	auipc	s2,0xf
    80001faa:	b9a90913          	addi	s2,s2,-1126 # 80010b40 <pid_lock>
    80001fae:	2781                	sext.w	a5,a5
    80001fb0:	079e                	slli	a5,a5,0x7
    80001fb2:	97ca                	add	a5,a5,s2
    80001fb4:	0ac7a983          	lw	s3,172(a5)
    80001fb8:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fba:	2781                	sext.w	a5,a5
    80001fbc:	079e                	slli	a5,a5,0x7
    80001fbe:	0000f597          	auipc	a1,0xf
    80001fc2:	bba58593          	addi	a1,a1,-1094 # 80010b78 <cpus+0x8>
    80001fc6:	95be                	add	a1,a1,a5
    80001fc8:	06048513          	addi	a0,s1,96
    80001fcc:	00001097          	auipc	ra,0x1
    80001fd0:	80c080e7          	jalr	-2036(ra) # 800027d8 <swtch>
    80001fd4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fd6:	2781                	sext.w	a5,a5
    80001fd8:	079e                	slli	a5,a5,0x7
    80001fda:	97ca                	add	a5,a5,s2
    80001fdc:	0b37a623          	sw	s3,172(a5)
}
    80001fe0:	70a2                	ld	ra,40(sp)
    80001fe2:	7402                	ld	s0,32(sp)
    80001fe4:	64e2                	ld	s1,24(sp)
    80001fe6:	6942                	ld	s2,16(sp)
    80001fe8:	69a2                	ld	s3,8(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret
    panic("sched p->lock");
    80001fee:	00006517          	auipc	a0,0x6
    80001ff2:	22a50513          	addi	a0,a0,554 # 80008218 <digits+0x1d8>
    80001ff6:	ffffe097          	auipc	ra,0xffffe
    80001ffa:	54e080e7          	jalr	1358(ra) # 80000544 <panic>
    panic("sched locks");
    80001ffe:	00006517          	auipc	a0,0x6
    80002002:	22a50513          	addi	a0,a0,554 # 80008228 <digits+0x1e8>
    80002006:	ffffe097          	auipc	ra,0xffffe
    8000200a:	53e080e7          	jalr	1342(ra) # 80000544 <panic>
    panic("sched running");
    8000200e:	00006517          	auipc	a0,0x6
    80002012:	22a50513          	addi	a0,a0,554 # 80008238 <digits+0x1f8>
    80002016:	ffffe097          	auipc	ra,0xffffe
    8000201a:	52e080e7          	jalr	1326(ra) # 80000544 <panic>
    panic("sched interruptible");
    8000201e:	00006517          	auipc	a0,0x6
    80002022:	22a50513          	addi	a0,a0,554 # 80008248 <digits+0x208>
    80002026:	ffffe097          	auipc	ra,0xffffe
    8000202a:	51e080e7          	jalr	1310(ra) # 80000544 <panic>

000000008000202e <yield>:
{
    8000202e:	1101                	addi	sp,sp,-32
    80002030:	ec06                	sd	ra,24(sp)
    80002032:	e822                	sd	s0,16(sp)
    80002034:	e426                	sd	s1,8(sp)
    80002036:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	98e080e7          	jalr	-1650(ra) # 800019c6 <myproc>
    80002040:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	ba8080e7          	jalr	-1112(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    8000204a:	478d                	li	a5,3
    8000204c:	cc9c                	sw	a5,24(s1)
  sched();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	f0a080e7          	jalr	-246(ra) # 80001f58 <sched>
  release(&p->lock);
    80002056:	8526                	mv	a0,s1
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	c46080e7          	jalr	-954(ra) # 80000c9e <release>
}
    80002060:	60e2                	ld	ra,24(sp)
    80002062:	6442                	ld	s0,16(sp)
    80002064:	64a2                	ld	s1,8(sp)
    80002066:	6105                	addi	sp,sp,32
    80002068:	8082                	ret

000000008000206a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000206a:	7179                	addi	sp,sp,-48
    8000206c:	f406                	sd	ra,40(sp)
    8000206e:	f022                	sd	s0,32(sp)
    80002070:	ec26                	sd	s1,24(sp)
    80002072:	e84a                	sd	s2,16(sp)
    80002074:	e44e                	sd	s3,8(sp)
    80002076:	1800                	addi	s0,sp,48
    80002078:	89aa                	mv	s3,a0
    8000207a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	94a080e7          	jalr	-1718(ra) # 800019c6 <myproc>
    80002084:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	b64080e7          	jalr	-1180(ra) # 80000bea <acquire>
  release(lk);
    8000208e:	854a                	mv	a0,s2
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	c0e080e7          	jalr	-1010(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002098:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000209c:	4789                	li	a5,2
    8000209e:	cc9c                	sw	a5,24(s1)

  sched();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	eb8080e7          	jalr	-328(ra) # 80001f58 <sched>

  // Tidy up.
  p->chan = 0;
    800020a8:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020ac:	8526                	mv	a0,s1
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	bf0080e7          	jalr	-1040(ra) # 80000c9e <release>
  acquire(lk);
    800020b6:	854a                	mv	a0,s2
    800020b8:	fffff097          	auipc	ra,0xfffff
    800020bc:	b32080e7          	jalr	-1230(ra) # 80000bea <acquire>
}
    800020c0:	70a2                	ld	ra,40(sp)
    800020c2:	7402                	ld	s0,32(sp)
    800020c4:	64e2                	ld	s1,24(sp)
    800020c6:	6942                	ld	s2,16(sp)
    800020c8:	69a2                	ld	s3,8(sp)
    800020ca:	6145                	addi	sp,sp,48
    800020cc:	8082                	ret

00000000800020ce <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020ce:	7139                	addi	sp,sp,-64
    800020d0:	fc06                	sd	ra,56(sp)
    800020d2:	f822                	sd	s0,48(sp)
    800020d4:	f426                	sd	s1,40(sp)
    800020d6:	f04a                	sd	s2,32(sp)
    800020d8:	ec4e                	sd	s3,24(sp)
    800020da:	e852                	sd	s4,16(sp)
    800020dc:	e456                	sd	s5,8(sp)
    800020de:	0080                	addi	s0,sp,64
    800020e0:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020e2:	0000f497          	auipc	s1,0xf
    800020e6:	e8e48493          	addi	s1,s1,-370 # 80010f70 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020ea:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020ec:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ee:	00015917          	auipc	s2,0x15
    800020f2:	88290913          	addi	s2,s2,-1918 # 80016970 <tickslock>
    800020f6:	a821                	j	8000210e <wakeup+0x40>
        p->state = RUNNABLE;
    800020f8:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800020fc:	8526                	mv	a0,s1
    800020fe:	fffff097          	auipc	ra,0xfffff
    80002102:	ba0080e7          	jalr	-1120(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002106:	16848493          	addi	s1,s1,360
    8000210a:	03248463          	beq	s1,s2,80002132 <wakeup+0x64>
    if(p != myproc()){
    8000210e:	00000097          	auipc	ra,0x0
    80002112:	8b8080e7          	jalr	-1864(ra) # 800019c6 <myproc>
    80002116:	fea488e3          	beq	s1,a0,80002106 <wakeup+0x38>
      acquire(&p->lock);
    8000211a:	8526                	mv	a0,s1
    8000211c:	fffff097          	auipc	ra,0xfffff
    80002120:	ace080e7          	jalr	-1330(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002124:	4c9c                	lw	a5,24(s1)
    80002126:	fd379be3          	bne	a5,s3,800020fc <wakeup+0x2e>
    8000212a:	709c                	ld	a5,32(s1)
    8000212c:	fd4798e3          	bne	a5,s4,800020fc <wakeup+0x2e>
    80002130:	b7e1                	j	800020f8 <wakeup+0x2a>
    }
  }
}
    80002132:	70e2                	ld	ra,56(sp)
    80002134:	7442                	ld	s0,48(sp)
    80002136:	74a2                	ld	s1,40(sp)
    80002138:	7902                	ld	s2,32(sp)
    8000213a:	69e2                	ld	s3,24(sp)
    8000213c:	6a42                	ld	s4,16(sp)
    8000213e:	6aa2                	ld	s5,8(sp)
    80002140:	6121                	addi	sp,sp,64
    80002142:	8082                	ret

0000000080002144 <reparent>:
{
    80002144:	7179                	addi	sp,sp,-48
    80002146:	f406                	sd	ra,40(sp)
    80002148:	f022                	sd	s0,32(sp)
    8000214a:	ec26                	sd	s1,24(sp)
    8000214c:	e84a                	sd	s2,16(sp)
    8000214e:	e44e                	sd	s3,8(sp)
    80002150:	e052                	sd	s4,0(sp)
    80002152:	1800                	addi	s0,sp,48
    80002154:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002156:	0000f497          	auipc	s1,0xf
    8000215a:	e1a48493          	addi	s1,s1,-486 # 80010f70 <proc>
      pp->parent = initproc;
    8000215e:	00006a17          	auipc	s4,0x6
    80002162:	76aa0a13          	addi	s4,s4,1898 # 800088c8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002166:	00015997          	auipc	s3,0x15
    8000216a:	80a98993          	addi	s3,s3,-2038 # 80016970 <tickslock>
    8000216e:	a029                	j	80002178 <reparent+0x34>
    80002170:	16848493          	addi	s1,s1,360
    80002174:	01348d63          	beq	s1,s3,8000218e <reparent+0x4a>
    if(pp->parent == p){
    80002178:	7c9c                	ld	a5,56(s1)
    8000217a:	ff279be3          	bne	a5,s2,80002170 <reparent+0x2c>
      pp->parent = initproc;
    8000217e:	000a3503          	ld	a0,0(s4)
    80002182:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002184:	00000097          	auipc	ra,0x0
    80002188:	f4a080e7          	jalr	-182(ra) # 800020ce <wakeup>
    8000218c:	b7d5                	j	80002170 <reparent+0x2c>
}
    8000218e:	70a2                	ld	ra,40(sp)
    80002190:	7402                	ld	s0,32(sp)
    80002192:	64e2                	ld	s1,24(sp)
    80002194:	6942                	ld	s2,16(sp)
    80002196:	69a2                	ld	s3,8(sp)
    80002198:	6a02                	ld	s4,0(sp)
    8000219a:	6145                	addi	sp,sp,48
    8000219c:	8082                	ret

000000008000219e <exit>:
{
    8000219e:	7179                	addi	sp,sp,-48
    800021a0:	f406                	sd	ra,40(sp)
    800021a2:	f022                	sd	s0,32(sp)
    800021a4:	ec26                	sd	s1,24(sp)
    800021a6:	e84a                	sd	s2,16(sp)
    800021a8:	e44e                	sd	s3,8(sp)
    800021aa:	e052                	sd	s4,0(sp)
    800021ac:	1800                	addi	s0,sp,48
    800021ae:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	816080e7          	jalr	-2026(ra) # 800019c6 <myproc>
    800021b8:	89aa                	mv	s3,a0
  if(p == initproc)
    800021ba:	00006797          	auipc	a5,0x6
    800021be:	70e7b783          	ld	a5,1806(a5) # 800088c8 <initproc>
    800021c2:	0d050493          	addi	s1,a0,208
    800021c6:	15050913          	addi	s2,a0,336
    800021ca:	02a79363          	bne	a5,a0,800021f0 <exit+0x52>
    panic("init exiting");
    800021ce:	00006517          	auipc	a0,0x6
    800021d2:	09250513          	addi	a0,a0,146 # 80008260 <digits+0x220>
    800021d6:	ffffe097          	auipc	ra,0xffffe
    800021da:	36e080e7          	jalr	878(ra) # 80000544 <panic>
      fileclose(f);
    800021de:	00002097          	auipc	ra,0x2
    800021e2:	604080e7          	jalr	1540(ra) # 800047e2 <fileclose>
      p->ofile[fd] = 0;
    800021e6:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800021ea:	04a1                	addi	s1,s1,8
    800021ec:	01248563          	beq	s1,s2,800021f6 <exit+0x58>
    if(p->ofile[fd]){
    800021f0:	6088                	ld	a0,0(s1)
    800021f2:	f575                	bnez	a0,800021de <exit+0x40>
    800021f4:	bfdd                	j	800021ea <exit+0x4c>
  begin_op();
    800021f6:	00002097          	auipc	ra,0x2
    800021fa:	120080e7          	jalr	288(ra) # 80004316 <begin_op>
  iput(p->cwd);
    800021fe:	1509b503          	ld	a0,336(s3)
    80002202:	00002097          	auipc	ra,0x2
    80002206:	90c080e7          	jalr	-1780(ra) # 80003b0e <iput>
  end_op();
    8000220a:	00002097          	auipc	ra,0x2
    8000220e:	18c080e7          	jalr	396(ra) # 80004396 <end_op>
  p->cwd = 0;
    80002212:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002216:	0000f497          	auipc	s1,0xf
    8000221a:	94248493          	addi	s1,s1,-1726 # 80010b58 <wait_lock>
    8000221e:	8526                	mv	a0,s1
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	9ca080e7          	jalr	-1590(ra) # 80000bea <acquire>
  reparent(p);
    80002228:	854e                	mv	a0,s3
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	f1a080e7          	jalr	-230(ra) # 80002144 <reparent>
  wakeup(p->parent);
    80002232:	0389b503          	ld	a0,56(s3)
    80002236:	00000097          	auipc	ra,0x0
    8000223a:	e98080e7          	jalr	-360(ra) # 800020ce <wakeup>
  acquire(&p->lock);
    8000223e:	854e                	mv	a0,s3
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	9aa080e7          	jalr	-1622(ra) # 80000bea <acquire>
  p->xstate = status;
    80002248:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000224c:	4795                	li	a5,5
    8000224e:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002252:	8526                	mv	a0,s1
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	a4a080e7          	jalr	-1462(ra) # 80000c9e <release>
  sched();
    8000225c:	00000097          	auipc	ra,0x0
    80002260:	cfc080e7          	jalr	-772(ra) # 80001f58 <sched>
  panic("zombie exit");
    80002264:	00006517          	auipc	a0,0x6
    80002268:	00c50513          	addi	a0,a0,12 # 80008270 <digits+0x230>
    8000226c:	ffffe097          	auipc	ra,0xffffe
    80002270:	2d8080e7          	jalr	728(ra) # 80000544 <panic>

0000000080002274 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002274:	7179                	addi	sp,sp,-48
    80002276:	f406                	sd	ra,40(sp)
    80002278:	f022                	sd	s0,32(sp)
    8000227a:	ec26                	sd	s1,24(sp)
    8000227c:	e84a                	sd	s2,16(sp)
    8000227e:	e44e                	sd	s3,8(sp)
    80002280:	1800                	addi	s0,sp,48
    80002282:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002284:	0000f497          	auipc	s1,0xf
    80002288:	cec48493          	addi	s1,s1,-788 # 80010f70 <proc>
    8000228c:	00014997          	auipc	s3,0x14
    80002290:	6e498993          	addi	s3,s3,1764 # 80016970 <tickslock>
    acquire(&p->lock);
    80002294:	8526                	mv	a0,s1
    80002296:	fffff097          	auipc	ra,0xfffff
    8000229a:	954080e7          	jalr	-1708(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000229e:	589c                	lw	a5,48(s1)
    800022a0:	01278d63          	beq	a5,s2,800022ba <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022a4:	8526                	mv	a0,s1
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	9f8080e7          	jalr	-1544(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022ae:	16848493          	addi	s1,s1,360
    800022b2:	ff3491e3          	bne	s1,s3,80002294 <kill+0x20>
  }
  return -1;
    800022b6:	557d                	li	a0,-1
    800022b8:	a829                	j	800022d2 <kill+0x5e>
      p->killed = 1;
    800022ba:	4785                	li	a5,1
    800022bc:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022be:	4c98                	lw	a4,24(s1)
    800022c0:	4789                	li	a5,2
    800022c2:	00f70f63          	beq	a4,a5,800022e0 <kill+0x6c>
      release(&p->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9d6080e7          	jalr	-1578(ra) # 80000c9e <release>
      return 0;
    800022d0:	4501                	li	a0,0
}
    800022d2:	70a2                	ld	ra,40(sp)
    800022d4:	7402                	ld	s0,32(sp)
    800022d6:	64e2                	ld	s1,24(sp)
    800022d8:	6942                	ld	s2,16(sp)
    800022da:	69a2                	ld	s3,8(sp)
    800022dc:	6145                	addi	sp,sp,48
    800022de:	8082                	ret
        p->state = RUNNABLE;
    800022e0:	478d                	li	a5,3
    800022e2:	cc9c                	sw	a5,24(s1)
    800022e4:	b7cd                	j	800022c6 <kill+0x52>

00000000800022e6 <setkilled>:

void
setkilled(struct proc *p)
{
    800022e6:	1101                	addi	sp,sp,-32
    800022e8:	ec06                	sd	ra,24(sp)
    800022ea:	e822                	sd	s0,16(sp)
    800022ec:	e426                	sd	s1,8(sp)
    800022ee:	1000                	addi	s0,sp,32
    800022f0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	8f8080e7          	jalr	-1800(ra) # 80000bea <acquire>
  p->killed = 1;
    800022fa:	4785                	li	a5,1
    800022fc:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	99e080e7          	jalr	-1634(ra) # 80000c9e <release>
}
    80002308:	60e2                	ld	ra,24(sp)
    8000230a:	6442                	ld	s0,16(sp)
    8000230c:	64a2                	ld	s1,8(sp)
    8000230e:	6105                	addi	sp,sp,32
    80002310:	8082                	ret

0000000080002312 <killed>:

int
killed(struct proc *p)
{
    80002312:	1101                	addi	sp,sp,-32
    80002314:	ec06                	sd	ra,24(sp)
    80002316:	e822                	sd	s0,16(sp)
    80002318:	e426                	sd	s1,8(sp)
    8000231a:	e04a                	sd	s2,0(sp)
    8000231c:	1000                	addi	s0,sp,32
    8000231e:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8ca080e7          	jalr	-1846(ra) # 80000bea <acquire>
  k = p->killed;
    80002328:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000232c:	8526                	mv	a0,s1
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	970080e7          	jalr	-1680(ra) # 80000c9e <release>
  return k;
}
    80002336:	854a                	mv	a0,s2
    80002338:	60e2                	ld	ra,24(sp)
    8000233a:	6442                	ld	s0,16(sp)
    8000233c:	64a2                	ld	s1,8(sp)
    8000233e:	6902                	ld	s2,0(sp)
    80002340:	6105                	addi	sp,sp,32
    80002342:	8082                	ret

0000000080002344 <wait>:
{
    80002344:	715d                	addi	sp,sp,-80
    80002346:	e486                	sd	ra,72(sp)
    80002348:	e0a2                	sd	s0,64(sp)
    8000234a:	fc26                	sd	s1,56(sp)
    8000234c:	f84a                	sd	s2,48(sp)
    8000234e:	f44e                	sd	s3,40(sp)
    80002350:	f052                	sd	s4,32(sp)
    80002352:	ec56                	sd	s5,24(sp)
    80002354:	e85a                	sd	s6,16(sp)
    80002356:	e45e                	sd	s7,8(sp)
    80002358:	e062                	sd	s8,0(sp)
    8000235a:	0880                	addi	s0,sp,80
    8000235c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000235e:	fffff097          	auipc	ra,0xfffff
    80002362:	668080e7          	jalr	1640(ra) # 800019c6 <myproc>
    80002366:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002368:	0000e517          	auipc	a0,0xe
    8000236c:	7f050513          	addi	a0,a0,2032 # 80010b58 <wait_lock>
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	87a080e7          	jalr	-1926(ra) # 80000bea <acquire>
    havekids = 0;
    80002378:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000237a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000237c:	00014997          	auipc	s3,0x14
    80002380:	5f498993          	addi	s3,s3,1524 # 80016970 <tickslock>
        havekids = 1;
    80002384:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002386:	0000ec17          	auipc	s8,0xe
    8000238a:	7d2c0c13          	addi	s8,s8,2002 # 80010b58 <wait_lock>
    havekids = 0;
    8000238e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002390:	0000f497          	auipc	s1,0xf
    80002394:	be048493          	addi	s1,s1,-1056 # 80010f70 <proc>
    80002398:	a0bd                	j	80002406 <wait+0xc2>
          pid = pp->pid;
    8000239a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000239e:	000b0e63          	beqz	s6,800023ba <wait+0x76>
    800023a2:	4691                	li	a3,4
    800023a4:	02c48613          	addi	a2,s1,44
    800023a8:	85da                	mv	a1,s6
    800023aa:	05093503          	ld	a0,80(s2)
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	2d6080e7          	jalr	726(ra) # 80001684 <copyout>
    800023b6:	02054563          	bltz	a0,800023e0 <wait+0x9c>
          freeproc(pp);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	7bc080e7          	jalr	1980(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8d8080e7          	jalr	-1832(ra) # 80000c9e <release>
          release(&wait_lock);
    800023ce:	0000e517          	auipc	a0,0xe
    800023d2:	78a50513          	addi	a0,a0,1930 # 80010b58 <wait_lock>
    800023d6:	fffff097          	auipc	ra,0xfffff
    800023da:	8c8080e7          	jalr	-1848(ra) # 80000c9e <release>
          return pid;
    800023de:	a0b5                	j	8000244a <wait+0x106>
            release(&pp->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8bc080e7          	jalr	-1860(ra) # 80000c9e <release>
            release(&wait_lock);
    800023ea:	0000e517          	auipc	a0,0xe
    800023ee:	76e50513          	addi	a0,a0,1902 # 80010b58 <wait_lock>
    800023f2:	fffff097          	auipc	ra,0xfffff
    800023f6:	8ac080e7          	jalr	-1876(ra) # 80000c9e <release>
            return -1;
    800023fa:	59fd                	li	s3,-1
    800023fc:	a0b9                	j	8000244a <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fe:	16848493          	addi	s1,s1,360
    80002402:	03348463          	beq	s1,s3,8000242a <wait+0xe6>
      if(pp->parent == p){
    80002406:	7c9c                	ld	a5,56(s1)
    80002408:	ff279be3          	bne	a5,s2,800023fe <wait+0xba>
        acquire(&pp->lock);
    8000240c:	8526                	mv	a0,s1
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7dc080e7          	jalr	2012(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002416:	4c9c                	lw	a5,24(s1)
    80002418:	f94781e3          	beq	a5,s4,8000239a <wait+0x56>
        release(&pp->lock);
    8000241c:	8526                	mv	a0,s1
    8000241e:	fffff097          	auipc	ra,0xfffff
    80002422:	880080e7          	jalr	-1920(ra) # 80000c9e <release>
        havekids = 1;
    80002426:	8756                	mv	a4,s5
    80002428:	bfd9                	j	800023fe <wait+0xba>
    if(!havekids || killed(p)){
    8000242a:	c719                	beqz	a4,80002438 <wait+0xf4>
    8000242c:	854a                	mv	a0,s2
    8000242e:	00000097          	auipc	ra,0x0
    80002432:	ee4080e7          	jalr	-284(ra) # 80002312 <killed>
    80002436:	c51d                	beqz	a0,80002464 <wait+0x120>
      release(&wait_lock);
    80002438:	0000e517          	auipc	a0,0xe
    8000243c:	72050513          	addi	a0,a0,1824 # 80010b58 <wait_lock>
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	85e080e7          	jalr	-1954(ra) # 80000c9e <release>
      return -1;
    80002448:	59fd                	li	s3,-1
}
    8000244a:	854e                	mv	a0,s3
    8000244c:	60a6                	ld	ra,72(sp)
    8000244e:	6406                	ld	s0,64(sp)
    80002450:	74e2                	ld	s1,56(sp)
    80002452:	7942                	ld	s2,48(sp)
    80002454:	79a2                	ld	s3,40(sp)
    80002456:	7a02                	ld	s4,32(sp)
    80002458:	6ae2                	ld	s5,24(sp)
    8000245a:	6b42                	ld	s6,16(sp)
    8000245c:	6ba2                	ld	s7,8(sp)
    8000245e:	6c02                	ld	s8,0(sp)
    80002460:	6161                	addi	sp,sp,80
    80002462:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002464:	85e2                	mv	a1,s8
    80002466:	854a                	mv	a0,s2
    80002468:	00000097          	auipc	ra,0x0
    8000246c:	c02080e7          	jalr	-1022(ra) # 8000206a <sleep>
    havekids = 0;
    80002470:	bf39                	j	8000238e <wait+0x4a>

0000000080002472 <waitall>:
{
    80002472:	7149                	addi	sp,sp,-368
    80002474:	f686                	sd	ra,360(sp)
    80002476:	f2a2                	sd	s0,352(sp)
    80002478:	eea6                	sd	s1,344(sp)
    8000247a:	eaca                	sd	s2,336(sp)
    8000247c:	e6ce                	sd	s3,328(sp)
    8000247e:	e2d2                	sd	s4,320(sp)
    80002480:	fe56                	sd	s5,312(sp)
    80002482:	fa5a                	sd	s6,304(sp)
    80002484:	f65e                	sd	s7,296(sp)
    80002486:	f262                	sd	s8,288(sp)
    80002488:	ee66                	sd	s9,280(sp)
    8000248a:	1a80                	addi	s0,sp,368
    8000248c:	8baa                	mv	s7,a0
    8000248e:	8c2e                	mv	s8,a1
  struct proc *p = myproc();
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	536080e7          	jalr	1334(ra) # 800019c6 <myproc>
  int count = 0;
    80002498:	f8042e23          	sw	zero,-100(s0)
  if(n == 0 || statuses == 0)
    8000249c:	180b8263          	beqz	s7,80002620 <waitall+0x1ae>
    800024a0:	84aa                	mv	s1,a0
    800024a2:	180c0163          	beqz	s8,80002624 <waitall+0x1b2>
  acquire(&wait_lock);
    800024a6:	0000e517          	auipc	a0,0xe
    800024aa:	6b250513          	addi	a0,a0,1714 # 80010b58 <wait_lock>
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	73c080e7          	jalr	1852(ra) # 80000bea <acquire>
    count = 0;
    800024b6:	4a81                	li	s5,0
        if(pp->state == ZOMBIE){
    800024b8:	4995                	li	s3,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ba:	00014917          	auipc	s2,0x14
    800024be:	4b690913          	addi	s2,s2,1206 # 80016970 <tickslock>
          count++;
    800024c2:	4a05                	li	s4,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c4:	0000eb17          	auipc	s6,0xe
    800024c8:	694b0b13          	addi	s6,s6,1684 # 80010b58 <wait_lock>
    800024cc:	a0f1                	j	80002598 <waitall+0x126>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024ce:	16878793          	addi	a5,a5,360
    800024d2:	03278463          	beq	a5,s2,800024fa <waitall+0x88>
      if(pp->parent == p){
    800024d6:	7f98                	ld	a4,56(a5)
    800024d8:	fe971be3          	bne	a4,s1,800024ce <waitall+0x5c>
        if(pp->state == ZOMBIE){
    800024dc:	4f98                	lw	a4,24(a5)
    800024de:	09371363          	bne	a4,s3,80002564 <waitall+0xf2>
          local_statuses[count] = pp->xstate;
    800024e2:	00269713          	slli	a4,a3,0x2
    800024e6:	fa040613          	addi	a2,s0,-96
    800024ea:	9732                	add	a4,a4,a2
    800024ec:	57d0                	lw	a2,44(a5)
    800024ee:	eec72c23          	sw	a2,-264(a4)
          count++;
    800024f2:	2685                	addiw	a3,a3,1
    800024f4:	8652                	mv	a2,s4
        havekids = 1;
    800024f6:	8cd2                	mv	s9,s4
    800024f8:	bfd9                	j	800024ce <waitall+0x5c>
    800024fa:	c219                	beqz	a2,80002500 <waitall+0x8e>
    800024fc:	f8d42e23          	sw	a3,-100(s0)
    if(!havekids){
    80002500:	000c8763          	beqz	s9,8000250e <waitall+0x9c>
        havekids = 1;
    80002504:	0000f797          	auipc	a5,0xf
    80002508:	a6c78793          	addi	a5,a5,-1428 # 80010f70 <proc>
    8000250c:	a0a5                	j	80002574 <waitall+0x102>
      if(copyout(p->pagetable, (uint64)n, (char *)&count, sizeof(int)) < 0){
    8000250e:	4691                	li	a3,4
    80002510:	f9c40613          	addi	a2,s0,-100
    80002514:	85de                	mv	a1,s7
    80002516:	68a8                	ld	a0,80(s1)
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	16c080e7          	jalr	364(ra) # 80001684 <copyout>
    80002520:	02054863          	bltz	a0,80002550 <waitall+0xde>
      release(&wait_lock);
    80002524:	0000e517          	auipc	a0,0xe
    80002528:	63450513          	addi	a0,a0,1588 # 80010b58 <wait_lock>
    8000252c:	ffffe097          	auipc	ra,0xffffe
    80002530:	772080e7          	jalr	1906(ra) # 80000c9e <release>
}
    80002534:	8566                	mv	a0,s9
    80002536:	70b6                	ld	ra,360(sp)
    80002538:	7416                	ld	s0,352(sp)
    8000253a:	64f6                	ld	s1,344(sp)
    8000253c:	6956                	ld	s2,336(sp)
    8000253e:	69b6                	ld	s3,328(sp)
    80002540:	6a16                	ld	s4,320(sp)
    80002542:	7af2                	ld	s5,312(sp)
    80002544:	7b52                	ld	s6,304(sp)
    80002546:	7bb2                	ld	s7,296(sp)
    80002548:	7c12                	ld	s8,288(sp)
    8000254a:	6cf2                	ld	s9,280(sp)
    8000254c:	6175                	addi	sp,sp,368
    8000254e:	8082                	ret
        release(&wait_lock);
    80002550:	0000e517          	auipc	a0,0xe
    80002554:	60850513          	addi	a0,a0,1544 # 80010b58 <wait_lock>
    80002558:	ffffe097          	auipc	ra,0xffffe
    8000255c:	746080e7          	jalr	1862(ra) # 80000c9e <release>
        return -1;
    80002560:	5cfd                	li	s9,-1
    80002562:	bfc9                	j	80002534 <waitall+0xc2>
    80002564:	d245                	beqz	a2,80002504 <waitall+0x92>
    80002566:	f8d42e23          	sw	a3,-100(s0)
    8000256a:	bf69                	j	80002504 <waitall+0x92>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000256c:	16878793          	addi	a5,a5,360
    80002570:	0b278c63          	beq	a5,s2,80002628 <waitall+0x1b6>
      if(pp->parent == p && pp->state != ZOMBIE){
    80002574:	7f98                	ld	a4,56(a5)
    80002576:	fe971be3          	bne	a4,s1,8000256c <waitall+0xfa>
    8000257a:	4f98                	lw	a4,24(a5)
    8000257c:	ff3708e3          	beq	a4,s3,8000256c <waitall+0xfa>
    if(killed(p)){
    80002580:	8526                	mv	a0,s1
    80002582:	00000097          	auipc	ra,0x0
    80002586:	d90080e7          	jalr	-624(ra) # 80002312 <killed>
    8000258a:	e149                	bnez	a0,8000260c <waitall+0x19a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000258c:	85da                	mv	a1,s6
    8000258e:	8526                	mv	a0,s1
    80002590:	00000097          	auipc	ra,0x0
    80002594:	ada080e7          	jalr	-1318(ra) # 8000206a <sleep>
    count = 0;
    80002598:	f8042e23          	sw	zero,-100(s0)
    8000259c:	8656                	mv	a2,s5
    8000259e:	86d6                	mv	a3,s5
    havekids = 0;
    800025a0:	8cd6                	mv	s9,s5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025a2:	0000f797          	auipc	a5,0xf
    800025a6:	9ce78793          	addi	a5,a5,-1586 # 80010f70 <proc>
    800025aa:	b735                	j	800024d6 <waitall+0x64>
        release(&wait_lock);
    800025ac:	0000e517          	auipc	a0,0xe
    800025b0:	5ac50513          	addi	a0,a0,1452 # 80010b58 <wait_lock>
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6ea080e7          	jalr	1770(ra) # 80000c9e <release>
        return -1;
    800025bc:	5cfd                	li	s9,-1
    800025be:	bf9d                	j	80002534 <waitall+0xc2>
      for(pp = proc; pp < &proc[NPROC]; pp++){
    800025c0:	16890913          	addi	s2,s2,360
    800025c4:	03390a63          	beq	s2,s3,800025f8 <waitall+0x186>
        if(pp->parent == p && pp->state == ZOMBIE){
    800025c8:	03893783          	ld	a5,56(s2)
    800025cc:	fe979ae3          	bne	a5,s1,800025c0 <waitall+0x14e>
    800025d0:	01892783          	lw	a5,24(s2)
    800025d4:	ff4796e3          	bne	a5,s4,800025c0 <waitall+0x14e>
          acquire(&pp->lock);
    800025d8:	854a                	mv	a0,s2
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	610080e7          	jalr	1552(ra) # 80000bea <acquire>
          freeproc(pp);
    800025e2:	854a                	mv	a0,s2
    800025e4:	fffff097          	auipc	ra,0xfffff
    800025e8:	594080e7          	jalr	1428(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800025ec:	854a                	mv	a0,s2
    800025ee:	ffffe097          	auipc	ra,0xffffe
    800025f2:	6b0080e7          	jalr	1712(ra) # 80000c9e <release>
    800025f6:	b7e9                	j	800025c0 <waitall+0x14e>
      release(&wait_lock);
    800025f8:	0000e517          	auipc	a0,0xe
    800025fc:	56050513          	addi	a0,a0,1376 # 80010b58 <wait_lock>
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	69e080e7          	jalr	1694(ra) # 80000c9e <release>
      return 0;
    80002608:	4c81                	li	s9,0
    8000260a:	b72d                	j	80002534 <waitall+0xc2>
      release(&wait_lock);
    8000260c:	0000e517          	auipc	a0,0xe
    80002610:	54c50513          	addi	a0,a0,1356 # 80010b58 <wait_lock>
    80002614:	ffffe097          	auipc	ra,0xffffe
    80002618:	68a080e7          	jalr	1674(ra) # 80000c9e <release>
      return -1;
    8000261c:	5cfd                	li	s9,-1
    8000261e:	bf19                	j	80002534 <waitall+0xc2>
    return -1;
    80002620:	5cfd                	li	s9,-1
    80002622:	bf09                	j	80002534 <waitall+0xc2>
    80002624:	5cfd                	li	s9,-1
    80002626:	b739                	j	80002534 <waitall+0xc2>
      if(copyout(p->pagetable, (uint64)n, (char *)&count, sizeof(int)) < 0){
    80002628:	4691                	li	a3,4
    8000262a:	f9c40613          	addi	a2,s0,-100
    8000262e:	85de                	mv	a1,s7
    80002630:	68a8                	ld	a0,80(s1)
    80002632:	fffff097          	auipc	ra,0xfffff
    80002636:	052080e7          	jalr	82(ra) # 80001684 <copyout>
    8000263a:	f60549e3          	bltz	a0,800025ac <waitall+0x13a>
      if(copyout(p->pagetable, (uint64)statuses, (char *)local_statuses, 
    8000263e:	f9c42683          	lw	a3,-100(s0)
    80002642:	068a                	slli	a3,a3,0x2
    80002644:	e9840613          	addi	a2,s0,-360
    80002648:	85e2                	mv	a1,s8
    8000264a:	68a8                	ld	a0,80(s1)
    8000264c:	fffff097          	auipc	ra,0xfffff
    80002650:	038080e7          	jalr	56(ra) # 80001684 <copyout>
      for(pp = proc; pp < &proc[NPROC]; pp++){
    80002654:	0000f917          	auipc	s2,0xf
    80002658:	91c90913          	addi	s2,s2,-1764 # 80010f70 <proc>
        if(pp->parent == p && pp->state == ZOMBIE){
    8000265c:	4a15                	li	s4,5
      for(pp = proc; pp < &proc[NPROC]; pp++){
    8000265e:	00014997          	auipc	s3,0x14
    80002662:	31298993          	addi	s3,s3,786 # 80016970 <tickslock>
      if(copyout(p->pagetable, (uint64)statuses, (char *)local_statuses, 
    80002666:	f60551e3          	bgez	a0,800025c8 <waitall+0x156>
        release(&wait_lock);
    8000266a:	0000e517          	auipc	a0,0xe
    8000266e:	4ee50513          	addi	a0,a0,1262 # 80010b58 <wait_lock>
    80002672:	ffffe097          	auipc	ra,0xffffe
    80002676:	62c080e7          	jalr	1580(ra) # 80000c9e <release>
        return -1;
    8000267a:	5cfd                	li	s9,-1
    8000267c:	bd65                	j	80002534 <waitall+0xc2>

000000008000267e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000267e:	7179                	addi	sp,sp,-48
    80002680:	f406                	sd	ra,40(sp)
    80002682:	f022                	sd	s0,32(sp)
    80002684:	ec26                	sd	s1,24(sp)
    80002686:	e84a                	sd	s2,16(sp)
    80002688:	e44e                	sd	s3,8(sp)
    8000268a:	e052                	sd	s4,0(sp)
    8000268c:	1800                	addi	s0,sp,48
    8000268e:	84aa                	mv	s1,a0
    80002690:	892e                	mv	s2,a1
    80002692:	89b2                	mv	s3,a2
    80002694:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	330080e7          	jalr	816(ra) # 800019c6 <myproc>
  if(user_dst){
    8000269e:	c08d                	beqz	s1,800026c0 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026a0:	86d2                	mv	a3,s4
    800026a2:	864e                	mv	a2,s3
    800026a4:	85ca                	mv	a1,s2
    800026a6:	6928                	ld	a0,80(a0)
    800026a8:	fffff097          	auipc	ra,0xfffff
    800026ac:	fdc080e7          	jalr	-36(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026b0:	70a2                	ld	ra,40(sp)
    800026b2:	7402                	ld	s0,32(sp)
    800026b4:	64e2                	ld	s1,24(sp)
    800026b6:	6942                	ld	s2,16(sp)
    800026b8:	69a2                	ld	s3,8(sp)
    800026ba:	6a02                	ld	s4,0(sp)
    800026bc:	6145                	addi	sp,sp,48
    800026be:	8082                	ret
    memmove((char *)dst, src, len);
    800026c0:	000a061b          	sext.w	a2,s4
    800026c4:	85ce                	mv	a1,s3
    800026c6:	854a                	mv	a0,s2
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	67e080e7          	jalr	1662(ra) # 80000d46 <memmove>
    return 0;
    800026d0:	8526                	mv	a0,s1
    800026d2:	bff9                	j	800026b0 <either_copyout+0x32>

00000000800026d4 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026d4:	7179                	addi	sp,sp,-48
    800026d6:	f406                	sd	ra,40(sp)
    800026d8:	f022                	sd	s0,32(sp)
    800026da:	ec26                	sd	s1,24(sp)
    800026dc:	e84a                	sd	s2,16(sp)
    800026de:	e44e                	sd	s3,8(sp)
    800026e0:	e052                	sd	s4,0(sp)
    800026e2:	1800                	addi	s0,sp,48
    800026e4:	892a                	mv	s2,a0
    800026e6:	84ae                	mv	s1,a1
    800026e8:	89b2                	mv	s3,a2
    800026ea:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026ec:	fffff097          	auipc	ra,0xfffff
    800026f0:	2da080e7          	jalr	730(ra) # 800019c6 <myproc>
  if(user_src){
    800026f4:	c08d                	beqz	s1,80002716 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026f6:	86d2                	mv	a3,s4
    800026f8:	864e                	mv	a2,s3
    800026fa:	85ca                	mv	a1,s2
    800026fc:	6928                	ld	a0,80(a0)
    800026fe:	fffff097          	auipc	ra,0xfffff
    80002702:	012080e7          	jalr	18(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002706:	70a2                	ld	ra,40(sp)
    80002708:	7402                	ld	s0,32(sp)
    8000270a:	64e2                	ld	s1,24(sp)
    8000270c:	6942                	ld	s2,16(sp)
    8000270e:	69a2                	ld	s3,8(sp)
    80002710:	6a02                	ld	s4,0(sp)
    80002712:	6145                	addi	sp,sp,48
    80002714:	8082                	ret
    memmove(dst, (char*)src, len);
    80002716:	000a061b          	sext.w	a2,s4
    8000271a:	85ce                	mv	a1,s3
    8000271c:	854a                	mv	a0,s2
    8000271e:	ffffe097          	auipc	ra,0xffffe
    80002722:	628080e7          	jalr	1576(ra) # 80000d46 <memmove>
    return 0;
    80002726:	8526                	mv	a0,s1
    80002728:	bff9                	j	80002706 <either_copyin+0x32>

000000008000272a <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000272a:	715d                	addi	sp,sp,-80
    8000272c:	e486                	sd	ra,72(sp)
    8000272e:	e0a2                	sd	s0,64(sp)
    80002730:	fc26                	sd	s1,56(sp)
    80002732:	f84a                	sd	s2,48(sp)
    80002734:	f44e                	sd	s3,40(sp)
    80002736:	f052                	sd	s4,32(sp)
    80002738:	ec56                	sd	s5,24(sp)
    8000273a:	e85a                	sd	s6,16(sp)
    8000273c:	e45e                	sd	s7,8(sp)
    8000273e:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002740:	00006517          	auipc	a0,0x6
    80002744:	98850513          	addi	a0,a0,-1656 # 800080c8 <digits+0x88>
    80002748:	ffffe097          	auipc	ra,0xffffe
    8000274c:	e46080e7          	jalr	-442(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002750:	0000f497          	auipc	s1,0xf
    80002754:	97848493          	addi	s1,s1,-1672 # 800110c8 <proc+0x158>
    80002758:	00014917          	auipc	s2,0x14
    8000275c:	37090913          	addi	s2,s2,880 # 80016ac8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002760:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002762:	00006997          	auipc	s3,0x6
    80002766:	b1e98993          	addi	s3,s3,-1250 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000276a:	00006a97          	auipc	s5,0x6
    8000276e:	b1ea8a93          	addi	s5,s5,-1250 # 80008288 <digits+0x248>
    printf("\n");
    80002772:	00006a17          	auipc	s4,0x6
    80002776:	956a0a13          	addi	s4,s4,-1706 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000277a:	00006b97          	auipc	s7,0x6
    8000277e:	b4eb8b93          	addi	s7,s7,-1202 # 800082c8 <states.1748>
    80002782:	a00d                	j	800027a4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002784:	ed86a583          	lw	a1,-296(a3)
    80002788:	8556                	mv	a0,s5
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	e04080e7          	jalr	-508(ra) # 8000058e <printf>
    printf("\n");
    80002792:	8552                	mv	a0,s4
    80002794:	ffffe097          	auipc	ra,0xffffe
    80002798:	dfa080e7          	jalr	-518(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000279c:	16848493          	addi	s1,s1,360
    800027a0:	03248163          	beq	s1,s2,800027c2 <procdump+0x98>
    if(p->state == UNUSED)
    800027a4:	86a6                	mv	a3,s1
    800027a6:	ec04a783          	lw	a5,-320(s1)
    800027aa:	dbed                	beqz	a5,8000279c <procdump+0x72>
      state = "???";
    800027ac:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027ae:	fcfb6be3          	bltu	s6,a5,80002784 <procdump+0x5a>
    800027b2:	1782                	slli	a5,a5,0x20
    800027b4:	9381                	srli	a5,a5,0x20
    800027b6:	078e                	slli	a5,a5,0x3
    800027b8:	97de                	add	a5,a5,s7
    800027ba:	6390                	ld	a2,0(a5)
    800027bc:	f661                	bnez	a2,80002784 <procdump+0x5a>
      state = "???";
    800027be:	864e                	mv	a2,s3
    800027c0:	b7d1                	j	80002784 <procdump+0x5a>
  }
}
    800027c2:	60a6                	ld	ra,72(sp)
    800027c4:	6406                	ld	s0,64(sp)
    800027c6:	74e2                	ld	s1,56(sp)
    800027c8:	7942                	ld	s2,48(sp)
    800027ca:	79a2                	ld	s3,40(sp)
    800027cc:	7a02                	ld	s4,32(sp)
    800027ce:	6ae2                	ld	s5,24(sp)
    800027d0:	6b42                	ld	s6,16(sp)
    800027d2:	6ba2                	ld	s7,8(sp)
    800027d4:	6161                	addi	sp,sp,80
    800027d6:	8082                	ret

00000000800027d8 <swtch>:
    800027d8:	00153023          	sd	ra,0(a0)
    800027dc:	00253423          	sd	sp,8(a0)
    800027e0:	e900                	sd	s0,16(a0)
    800027e2:	ed04                	sd	s1,24(a0)
    800027e4:	03253023          	sd	s2,32(a0)
    800027e8:	03353423          	sd	s3,40(a0)
    800027ec:	03453823          	sd	s4,48(a0)
    800027f0:	03553c23          	sd	s5,56(a0)
    800027f4:	05653023          	sd	s6,64(a0)
    800027f8:	05753423          	sd	s7,72(a0)
    800027fc:	05853823          	sd	s8,80(a0)
    80002800:	05953c23          	sd	s9,88(a0)
    80002804:	07a53023          	sd	s10,96(a0)
    80002808:	07b53423          	sd	s11,104(a0)
    8000280c:	0005b083          	ld	ra,0(a1)
    80002810:	0085b103          	ld	sp,8(a1)
    80002814:	6980                	ld	s0,16(a1)
    80002816:	6d84                	ld	s1,24(a1)
    80002818:	0205b903          	ld	s2,32(a1)
    8000281c:	0285b983          	ld	s3,40(a1)
    80002820:	0305ba03          	ld	s4,48(a1)
    80002824:	0385ba83          	ld	s5,56(a1)
    80002828:	0405bb03          	ld	s6,64(a1)
    8000282c:	0485bb83          	ld	s7,72(a1)
    80002830:	0505bc03          	ld	s8,80(a1)
    80002834:	0585bc83          	ld	s9,88(a1)
    80002838:	0605bd03          	ld	s10,96(a1)
    8000283c:	0685bd83          	ld	s11,104(a1)
    80002840:	8082                	ret

0000000080002842 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002842:	1141                	addi	sp,sp,-16
    80002844:	e406                	sd	ra,8(sp)
    80002846:	e022                	sd	s0,0(sp)
    80002848:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000284a:	00006597          	auipc	a1,0x6
    8000284e:	aae58593          	addi	a1,a1,-1362 # 800082f8 <states.1748+0x30>
    80002852:	00014517          	auipc	a0,0x14
    80002856:	11e50513          	addi	a0,a0,286 # 80016970 <tickslock>
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	300080e7          	jalr	768(ra) # 80000b5a <initlock>
}
    80002862:	60a2                	ld	ra,8(sp)
    80002864:	6402                	ld	s0,0(sp)
    80002866:	0141                	addi	sp,sp,16
    80002868:	8082                	ret

000000008000286a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000286a:	1141                	addi	sp,sp,-16
    8000286c:	e422                	sd	s0,8(sp)
    8000286e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002870:	00003797          	auipc	a5,0x3
    80002874:	5b078793          	addi	a5,a5,1456 # 80005e20 <kernelvec>
    80002878:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000287c:	6422                	ld	s0,8(sp)
    8000287e:	0141                	addi	sp,sp,16
    80002880:	8082                	ret

0000000080002882 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002882:	1141                	addi	sp,sp,-16
    80002884:	e406                	sd	ra,8(sp)
    80002886:	e022                	sd	s0,0(sp)
    80002888:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000288a:	fffff097          	auipc	ra,0xfffff
    8000288e:	13c080e7          	jalr	316(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002892:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002896:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002898:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000289c:	00004617          	auipc	a2,0x4
    800028a0:	76460613          	addi	a2,a2,1892 # 80007000 <_trampoline>
    800028a4:	00004697          	auipc	a3,0x4
    800028a8:	75c68693          	addi	a3,a3,1884 # 80007000 <_trampoline>
    800028ac:	8e91                	sub	a3,a3,a2
    800028ae:	040007b7          	lui	a5,0x4000
    800028b2:	17fd                	addi	a5,a5,-1
    800028b4:	07b2                	slli	a5,a5,0xc
    800028b6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028b8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028be:	180026f3          	csrr	a3,satp
    800028c2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028c4:	6d38                	ld	a4,88(a0)
    800028c6:	6134                	ld	a3,64(a0)
    800028c8:	6585                	lui	a1,0x1
    800028ca:	96ae                	add	a3,a3,a1
    800028cc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028ce:	6d38                	ld	a4,88(a0)
    800028d0:	00000697          	auipc	a3,0x0
    800028d4:	13068693          	addi	a3,a3,304 # 80002a00 <usertrap>
    800028d8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028da:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028dc:	8692                	mv	a3,tp
    800028de:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028e4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028e8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ec:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028f0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028f2:	6f18                	ld	a4,24(a4)
    800028f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800028f8:	6928                	ld	a0,80(a0)
    800028fa:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800028fc:	00004717          	auipc	a4,0x4
    80002900:	7a070713          	addi	a4,a4,1952 # 8000709c <userret>
    80002904:	8f11                	sub	a4,a4,a2
    80002906:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002908:	577d                	li	a4,-1
    8000290a:	177e                	slli	a4,a4,0x3f
    8000290c:	8d59                	or	a0,a0,a4
    8000290e:	9782                	jalr	a5
}
    80002910:	60a2                	ld	ra,8(sp)
    80002912:	6402                	ld	s0,0(sp)
    80002914:	0141                	addi	sp,sp,16
    80002916:	8082                	ret

0000000080002918 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002918:	1101                	addi	sp,sp,-32
    8000291a:	ec06                	sd	ra,24(sp)
    8000291c:	e822                	sd	s0,16(sp)
    8000291e:	e426                	sd	s1,8(sp)
    80002920:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002922:	00014497          	auipc	s1,0x14
    80002926:	04e48493          	addi	s1,s1,78 # 80016970 <tickslock>
    8000292a:	8526                	mv	a0,s1
    8000292c:	ffffe097          	auipc	ra,0xffffe
    80002930:	2be080e7          	jalr	702(ra) # 80000bea <acquire>
  ticks++;
    80002934:	00006517          	auipc	a0,0x6
    80002938:	f9c50513          	addi	a0,a0,-100 # 800088d0 <ticks>
    8000293c:	411c                	lw	a5,0(a0)
    8000293e:	2785                	addiw	a5,a5,1
    80002940:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002942:	fffff097          	auipc	ra,0xfffff
    80002946:	78c080e7          	jalr	1932(ra) # 800020ce <wakeup>
  release(&tickslock);
    8000294a:	8526                	mv	a0,s1
    8000294c:	ffffe097          	auipc	ra,0xffffe
    80002950:	352080e7          	jalr	850(ra) # 80000c9e <release>
}
    80002954:	60e2                	ld	ra,24(sp)
    80002956:	6442                	ld	s0,16(sp)
    80002958:	64a2                	ld	s1,8(sp)
    8000295a:	6105                	addi	sp,sp,32
    8000295c:	8082                	ret

000000008000295e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000295e:	1101                	addi	sp,sp,-32
    80002960:	ec06                	sd	ra,24(sp)
    80002962:	e822                	sd	s0,16(sp)
    80002964:	e426                	sd	s1,8(sp)
    80002966:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002968:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000296c:	00074d63          	bltz	a4,80002986 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002970:	57fd                	li	a5,-1
    80002972:	17fe                	slli	a5,a5,0x3f
    80002974:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002976:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002978:	06f70363          	beq	a4,a5,800029de <devintr+0x80>
  }
}
    8000297c:	60e2                	ld	ra,24(sp)
    8000297e:	6442                	ld	s0,16(sp)
    80002980:	64a2                	ld	s1,8(sp)
    80002982:	6105                	addi	sp,sp,32
    80002984:	8082                	ret
     (scause & 0xff) == 9){
    80002986:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000298a:	46a5                	li	a3,9
    8000298c:	fed792e3          	bne	a5,a3,80002970 <devintr+0x12>
    int irq = plic_claim();
    80002990:	00003097          	auipc	ra,0x3
    80002994:	598080e7          	jalr	1432(ra) # 80005f28 <plic_claim>
    80002998:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000299a:	47a9                	li	a5,10
    8000299c:	02f50763          	beq	a0,a5,800029ca <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029a0:	4785                	li	a5,1
    800029a2:	02f50963          	beq	a0,a5,800029d4 <devintr+0x76>
    return 1;
    800029a6:	4505                	li	a0,1
    } else if(irq){
    800029a8:	d8f1                	beqz	s1,8000297c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029aa:	85a6                	mv	a1,s1
    800029ac:	00006517          	auipc	a0,0x6
    800029b0:	95450513          	addi	a0,a0,-1708 # 80008300 <states.1748+0x38>
    800029b4:	ffffe097          	auipc	ra,0xffffe
    800029b8:	bda080e7          	jalr	-1062(ra) # 8000058e <printf>
      plic_complete(irq);
    800029bc:	8526                	mv	a0,s1
    800029be:	00003097          	auipc	ra,0x3
    800029c2:	58e080e7          	jalr	1422(ra) # 80005f4c <plic_complete>
    return 1;
    800029c6:	4505                	li	a0,1
    800029c8:	bf55                	j	8000297c <devintr+0x1e>
      uartintr();
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	fe4080e7          	jalr	-28(ra) # 800009ae <uartintr>
    800029d2:	b7ed                	j	800029bc <devintr+0x5e>
      virtio_disk_intr();
    800029d4:	00004097          	auipc	ra,0x4
    800029d8:	aa2080e7          	jalr	-1374(ra) # 80006476 <virtio_disk_intr>
    800029dc:	b7c5                	j	800029bc <devintr+0x5e>
    if(cpuid() == 0){
    800029de:	fffff097          	auipc	ra,0xfffff
    800029e2:	fbc080e7          	jalr	-68(ra) # 8000199a <cpuid>
    800029e6:	c901                	beqz	a0,800029f6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029e8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029ee:	14479073          	csrw	sip,a5
    return 2;
    800029f2:	4509                	li	a0,2
    800029f4:	b761                	j	8000297c <devintr+0x1e>
      clockintr();
    800029f6:	00000097          	auipc	ra,0x0
    800029fa:	f22080e7          	jalr	-222(ra) # 80002918 <clockintr>
    800029fe:	b7ed                	j	800029e8 <devintr+0x8a>

0000000080002a00 <usertrap>:
{
    80002a00:	1101                	addi	sp,sp,-32
    80002a02:	ec06                	sd	ra,24(sp)
    80002a04:	e822                	sd	s0,16(sp)
    80002a06:	e426                	sd	s1,8(sp)
    80002a08:	e04a                	sd	s2,0(sp)
    80002a0a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a10:	1007f793          	andi	a5,a5,256
    80002a14:	e3b1                	bnez	a5,80002a58 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a16:	00003797          	auipc	a5,0x3
    80002a1a:	40a78793          	addi	a5,a5,1034 # 80005e20 <kernelvec>
    80002a1e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a22:	fffff097          	auipc	ra,0xfffff
    80002a26:	fa4080e7          	jalr	-92(ra) # 800019c6 <myproc>
    80002a2a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a2c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a2e:	14102773          	csrr	a4,sepc
    80002a32:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a34:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a38:	47a1                	li	a5,8
    80002a3a:	02f70763          	beq	a4,a5,80002a68 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a3e:	00000097          	auipc	ra,0x0
    80002a42:	f20080e7          	jalr	-224(ra) # 8000295e <devintr>
    80002a46:	892a                	mv	s2,a0
    80002a48:	c151                	beqz	a0,80002acc <usertrap+0xcc>
  if(killed(p))
    80002a4a:	8526                	mv	a0,s1
    80002a4c:	00000097          	auipc	ra,0x0
    80002a50:	8c6080e7          	jalr	-1850(ra) # 80002312 <killed>
    80002a54:	c929                	beqz	a0,80002aa6 <usertrap+0xa6>
    80002a56:	a099                	j	80002a9c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a58:	00006517          	auipc	a0,0x6
    80002a5c:	8c850513          	addi	a0,a0,-1848 # 80008320 <states.1748+0x58>
    80002a60:	ffffe097          	auipc	ra,0xffffe
    80002a64:	ae4080e7          	jalr	-1308(ra) # 80000544 <panic>
    if(killed(p))
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	8aa080e7          	jalr	-1878(ra) # 80002312 <killed>
    80002a70:	e921                	bnez	a0,80002ac0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002a72:	6cb8                	ld	a4,88(s1)
    80002a74:	6f1c                	ld	a5,24(a4)
    80002a76:	0791                	addi	a5,a5,4
    80002a78:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a7e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a82:	10079073          	csrw	sstatus,a5
    syscall();
    80002a86:	00000097          	auipc	ra,0x0
    80002a8a:	2d4080e7          	jalr	724(ra) # 80002d5a <syscall>
  if(killed(p))
    80002a8e:	8526                	mv	a0,s1
    80002a90:	00000097          	auipc	ra,0x0
    80002a94:	882080e7          	jalr	-1918(ra) # 80002312 <killed>
    80002a98:	c911                	beqz	a0,80002aac <usertrap+0xac>
    80002a9a:	4901                	li	s2,0
    exit(-1);
    80002a9c:	557d                	li	a0,-1
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	700080e7          	jalr	1792(ra) # 8000219e <exit>
  if(which_dev == 2)
    80002aa6:	4789                	li	a5,2
    80002aa8:	04f90f63          	beq	s2,a5,80002b06 <usertrap+0x106>
  usertrapret();
    80002aac:	00000097          	auipc	ra,0x0
    80002ab0:	dd6080e7          	jalr	-554(ra) # 80002882 <usertrapret>
}
    80002ab4:	60e2                	ld	ra,24(sp)
    80002ab6:	6442                	ld	s0,16(sp)
    80002ab8:	64a2                	ld	s1,8(sp)
    80002aba:	6902                	ld	s2,0(sp)
    80002abc:	6105                	addi	sp,sp,32
    80002abe:	8082                	ret
      exit(-1);
    80002ac0:	557d                	li	a0,-1
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	6dc080e7          	jalr	1756(ra) # 8000219e <exit>
    80002aca:	b765                	j	80002a72 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002acc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002ad0:	5890                	lw	a2,48(s1)
    80002ad2:	00006517          	auipc	a0,0x6
    80002ad6:	86e50513          	addi	a0,a0,-1938 # 80008340 <states.1748+0x78>
    80002ada:	ffffe097          	auipc	ra,0xffffe
    80002ade:	ab4080e7          	jalr	-1356(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ae6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aea:	00006517          	auipc	a0,0x6
    80002aee:	88650513          	addi	a0,a0,-1914 # 80008370 <states.1748+0xa8>
    80002af2:	ffffe097          	auipc	ra,0xffffe
    80002af6:	a9c080e7          	jalr	-1380(ra) # 8000058e <printf>
    setkilled(p);
    80002afa:	8526                	mv	a0,s1
    80002afc:	fffff097          	auipc	ra,0xfffff
    80002b00:	7ea080e7          	jalr	2026(ra) # 800022e6 <setkilled>
    80002b04:	b769                	j	80002a8e <usertrap+0x8e>
    yield();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	528080e7          	jalr	1320(ra) # 8000202e <yield>
    80002b0e:	bf79                	j	80002aac <usertrap+0xac>

0000000080002b10 <kerneltrap>:
{
    80002b10:	7179                	addi	sp,sp,-48
    80002b12:	f406                	sd	ra,40(sp)
    80002b14:	f022                	sd	s0,32(sp)
    80002b16:	ec26                	sd	s1,24(sp)
    80002b18:	e84a                	sd	s2,16(sp)
    80002b1a:	e44e                	sd	s3,8(sp)
    80002b1c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b1e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b22:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b26:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b2a:	1004f793          	andi	a5,s1,256
    80002b2e:	cb85                	beqz	a5,80002b5e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b30:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b34:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b36:	ef85                	bnez	a5,80002b6e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	e26080e7          	jalr	-474(ra) # 8000295e <devintr>
    80002b40:	cd1d                	beqz	a0,80002b7e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b42:	4789                	li	a5,2
    80002b44:	06f50a63          	beq	a0,a5,80002bb8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b48:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b4c:	10049073          	csrw	sstatus,s1
}
    80002b50:	70a2                	ld	ra,40(sp)
    80002b52:	7402                	ld	s0,32(sp)
    80002b54:	64e2                	ld	s1,24(sp)
    80002b56:	6942                	ld	s2,16(sp)
    80002b58:	69a2                	ld	s3,8(sp)
    80002b5a:	6145                	addi	sp,sp,48
    80002b5c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b5e:	00006517          	auipc	a0,0x6
    80002b62:	83250513          	addi	a0,a0,-1998 # 80008390 <states.1748+0xc8>
    80002b66:	ffffe097          	auipc	ra,0xffffe
    80002b6a:	9de080e7          	jalr	-1570(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b6e:	00006517          	auipc	a0,0x6
    80002b72:	84a50513          	addi	a0,a0,-1974 # 800083b8 <states.1748+0xf0>
    80002b76:	ffffe097          	auipc	ra,0xffffe
    80002b7a:	9ce080e7          	jalr	-1586(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002b7e:	85ce                	mv	a1,s3
    80002b80:	00006517          	auipc	a0,0x6
    80002b84:	85850513          	addi	a0,a0,-1960 # 800083d8 <states.1748+0x110>
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	a06080e7          	jalr	-1530(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b94:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b98:	00006517          	auipc	a0,0x6
    80002b9c:	85050513          	addi	a0,a0,-1968 # 800083e8 <states.1748+0x120>
    80002ba0:	ffffe097          	auipc	ra,0xffffe
    80002ba4:	9ee080e7          	jalr	-1554(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002ba8:	00006517          	auipc	a0,0x6
    80002bac:	85850513          	addi	a0,a0,-1960 # 80008400 <states.1748+0x138>
    80002bb0:	ffffe097          	auipc	ra,0xffffe
    80002bb4:	994080e7          	jalr	-1644(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bb8:	fffff097          	auipc	ra,0xfffff
    80002bbc:	e0e080e7          	jalr	-498(ra) # 800019c6 <myproc>
    80002bc0:	d541                	beqz	a0,80002b48 <kerneltrap+0x38>
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	e04080e7          	jalr	-508(ra) # 800019c6 <myproc>
    80002bca:	4d18                	lw	a4,24(a0)
    80002bcc:	4791                	li	a5,4
    80002bce:	f6f71de3          	bne	a4,a5,80002b48 <kerneltrap+0x38>
    yield();
    80002bd2:	fffff097          	auipc	ra,0xfffff
    80002bd6:	45c080e7          	jalr	1116(ra) # 8000202e <yield>
    80002bda:	b7bd                	j	80002b48 <kerneltrap+0x38>

0000000080002bdc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bdc:	1101                	addi	sp,sp,-32
    80002bde:	ec06                	sd	ra,24(sp)
    80002be0:	e822                	sd	s0,16(sp)
    80002be2:	e426                	sd	s1,8(sp)
    80002be4:	1000                	addi	s0,sp,32
    80002be6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	dde080e7          	jalr	-546(ra) # 800019c6 <myproc>
  switch (n) {
    80002bf0:	4795                	li	a5,5
    80002bf2:	0497e163          	bltu	a5,s1,80002c34 <argraw+0x58>
    80002bf6:	048a                	slli	s1,s1,0x2
    80002bf8:	00006717          	auipc	a4,0x6
    80002bfc:	84070713          	addi	a4,a4,-1984 # 80008438 <states.1748+0x170>
    80002c00:	94ba                	add	s1,s1,a4
    80002c02:	409c                	lw	a5,0(s1)
    80002c04:	97ba                	add	a5,a5,a4
    80002c06:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c08:	6d3c                	ld	a5,88(a0)
    80002c0a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c0c:	60e2                	ld	ra,24(sp)
    80002c0e:	6442                	ld	s0,16(sp)
    80002c10:	64a2                	ld	s1,8(sp)
    80002c12:	6105                	addi	sp,sp,32
    80002c14:	8082                	ret
    return p->trapframe->a1;
    80002c16:	6d3c                	ld	a5,88(a0)
    80002c18:	7fa8                	ld	a0,120(a5)
    80002c1a:	bfcd                	j	80002c0c <argraw+0x30>
    return p->trapframe->a2;
    80002c1c:	6d3c                	ld	a5,88(a0)
    80002c1e:	63c8                	ld	a0,128(a5)
    80002c20:	b7f5                	j	80002c0c <argraw+0x30>
    return p->trapframe->a3;
    80002c22:	6d3c                	ld	a5,88(a0)
    80002c24:	67c8                	ld	a0,136(a5)
    80002c26:	b7dd                	j	80002c0c <argraw+0x30>
    return p->trapframe->a4;
    80002c28:	6d3c                	ld	a5,88(a0)
    80002c2a:	6bc8                	ld	a0,144(a5)
    80002c2c:	b7c5                	j	80002c0c <argraw+0x30>
    return p->trapframe->a5;
    80002c2e:	6d3c                	ld	a5,88(a0)
    80002c30:	6fc8                	ld	a0,152(a5)
    80002c32:	bfe9                	j	80002c0c <argraw+0x30>
  panic("argraw");
    80002c34:	00005517          	auipc	a0,0x5
    80002c38:	7dc50513          	addi	a0,a0,2012 # 80008410 <states.1748+0x148>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	908080e7          	jalr	-1784(ra) # 80000544 <panic>

0000000080002c44 <fetchaddr>:
{
    80002c44:	1101                	addi	sp,sp,-32
    80002c46:	ec06                	sd	ra,24(sp)
    80002c48:	e822                	sd	s0,16(sp)
    80002c4a:	e426                	sd	s1,8(sp)
    80002c4c:	e04a                	sd	s2,0(sp)
    80002c4e:	1000                	addi	s0,sp,32
    80002c50:	84aa                	mv	s1,a0
    80002c52:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c54:	fffff097          	auipc	ra,0xfffff
    80002c58:	d72080e7          	jalr	-654(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c5c:	653c                	ld	a5,72(a0)
    80002c5e:	02f4f863          	bgeu	s1,a5,80002c8e <fetchaddr+0x4a>
    80002c62:	00848713          	addi	a4,s1,8
    80002c66:	02e7e663          	bltu	a5,a4,80002c92 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c6a:	46a1                	li	a3,8
    80002c6c:	8626                	mv	a2,s1
    80002c6e:	85ca                	mv	a1,s2
    80002c70:	6928                	ld	a0,80(a0)
    80002c72:	fffff097          	auipc	ra,0xfffff
    80002c76:	a9e080e7          	jalr	-1378(ra) # 80001710 <copyin>
    80002c7a:	00a03533          	snez	a0,a0
    80002c7e:	40a00533          	neg	a0,a0
}
    80002c82:	60e2                	ld	ra,24(sp)
    80002c84:	6442                	ld	s0,16(sp)
    80002c86:	64a2                	ld	s1,8(sp)
    80002c88:	6902                	ld	s2,0(sp)
    80002c8a:	6105                	addi	sp,sp,32
    80002c8c:	8082                	ret
    return -1;
    80002c8e:	557d                	li	a0,-1
    80002c90:	bfcd                	j	80002c82 <fetchaddr+0x3e>
    80002c92:	557d                	li	a0,-1
    80002c94:	b7fd                	j	80002c82 <fetchaddr+0x3e>

0000000080002c96 <fetchstr>:
{
    80002c96:	7179                	addi	sp,sp,-48
    80002c98:	f406                	sd	ra,40(sp)
    80002c9a:	f022                	sd	s0,32(sp)
    80002c9c:	ec26                	sd	s1,24(sp)
    80002c9e:	e84a                	sd	s2,16(sp)
    80002ca0:	e44e                	sd	s3,8(sp)
    80002ca2:	1800                	addi	s0,sp,48
    80002ca4:	892a                	mv	s2,a0
    80002ca6:	84ae                	mv	s1,a1
    80002ca8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002caa:	fffff097          	auipc	ra,0xfffff
    80002cae:	d1c080e7          	jalr	-740(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002cb2:	86ce                	mv	a3,s3
    80002cb4:	864a                	mv	a2,s2
    80002cb6:	85a6                	mv	a1,s1
    80002cb8:	6928                	ld	a0,80(a0)
    80002cba:	fffff097          	auipc	ra,0xfffff
    80002cbe:	ae2080e7          	jalr	-1310(ra) # 8000179c <copyinstr>
    80002cc2:	00054e63          	bltz	a0,80002cde <fetchstr+0x48>
  return strlen(buf);
    80002cc6:	8526                	mv	a0,s1
    80002cc8:	ffffe097          	auipc	ra,0xffffe
    80002ccc:	1a2080e7          	jalr	418(ra) # 80000e6a <strlen>
}
    80002cd0:	70a2                	ld	ra,40(sp)
    80002cd2:	7402                	ld	s0,32(sp)
    80002cd4:	64e2                	ld	s1,24(sp)
    80002cd6:	6942                	ld	s2,16(sp)
    80002cd8:	69a2                	ld	s3,8(sp)
    80002cda:	6145                	addi	sp,sp,48
    80002cdc:	8082                	ret
    return -1;
    80002cde:	557d                	li	a0,-1
    80002ce0:	bfc5                	j	80002cd0 <fetchstr+0x3a>

0000000080002ce2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002ce2:	1101                	addi	sp,sp,-32
    80002ce4:	ec06                	sd	ra,24(sp)
    80002ce6:	e822                	sd	s0,16(sp)
    80002ce8:	e426                	sd	s1,8(sp)
    80002cea:	1000                	addi	s0,sp,32
    80002cec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cee:	00000097          	auipc	ra,0x0
    80002cf2:	eee080e7          	jalr	-274(ra) # 80002bdc <argraw>
    80002cf6:	c088                	sw	a0,0(s1)
}
    80002cf8:	60e2                	ld	ra,24(sp)
    80002cfa:	6442                	ld	s0,16(sp)
    80002cfc:	64a2                	ld	s1,8(sp)
    80002cfe:	6105                	addi	sp,sp,32
    80002d00:	8082                	ret

0000000080002d02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d02:	1101                	addi	sp,sp,-32
    80002d04:	ec06                	sd	ra,24(sp)
    80002d06:	e822                	sd	s0,16(sp)
    80002d08:	e426                	sd	s1,8(sp)
    80002d0a:	1000                	addi	s0,sp,32
    80002d0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	ece080e7          	jalr	-306(ra) # 80002bdc <argraw>
    80002d16:	e088                	sd	a0,0(s1)
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6105                	addi	sp,sp,32
    80002d20:	8082                	ret

0000000080002d22 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d22:	7179                	addi	sp,sp,-48
    80002d24:	f406                	sd	ra,40(sp)
    80002d26:	f022                	sd	s0,32(sp)
    80002d28:	ec26                	sd	s1,24(sp)
    80002d2a:	e84a                	sd	s2,16(sp)
    80002d2c:	1800                	addi	s0,sp,48
    80002d2e:	84ae                	mv	s1,a1
    80002d30:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d32:	fd840593          	addi	a1,s0,-40
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	fcc080e7          	jalr	-52(ra) # 80002d02 <argaddr>
  return fetchstr(addr, buf, max);
    80002d3e:	864a                	mv	a2,s2
    80002d40:	85a6                	mv	a1,s1
    80002d42:	fd843503          	ld	a0,-40(s0)
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	f50080e7          	jalr	-176(ra) # 80002c96 <fetchstr>
}
    80002d4e:	70a2                	ld	ra,40(sp)
    80002d50:	7402                	ld	s0,32(sp)
    80002d52:	64e2                	ld	s1,24(sp)
    80002d54:	6942                	ld	s2,16(sp)
    80002d56:	6145                	addi	sp,sp,48
    80002d58:	8082                	ret

0000000080002d5a <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d5a:	1101                	addi	sp,sp,-32
    80002d5c:	ec06                	sd	ra,24(sp)
    80002d5e:	e822                	sd	s0,16(sp)
    80002d60:	e426                	sd	s1,8(sp)
    80002d62:	e04a                	sd	s2,0(sp)
    80002d64:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	c60080e7          	jalr	-928(ra) # 800019c6 <myproc>
    80002d6e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d70:	05853903          	ld	s2,88(a0)
    80002d74:	0a893783          	ld	a5,168(s2)
    80002d78:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d7c:	37fd                	addiw	a5,a5,-1
    80002d7e:	4759                	li	a4,22
    80002d80:	00f76f63          	bltu	a4,a5,80002d9e <syscall+0x44>
    80002d84:	00369713          	slli	a4,a3,0x3
    80002d88:	00005797          	auipc	a5,0x5
    80002d8c:	6c878793          	addi	a5,a5,1736 # 80008450 <syscalls>
    80002d90:	97ba                	add	a5,a5,a4
    80002d92:	639c                	ld	a5,0(a5)
    80002d94:	c789                	beqz	a5,80002d9e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002d96:	9782                	jalr	a5
    80002d98:	06a93823          	sd	a0,112(s2)
    80002d9c:	a839                	j	80002dba <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d9e:	15848613          	addi	a2,s1,344
    80002da2:	588c                	lw	a1,48(s1)
    80002da4:	00005517          	auipc	a0,0x5
    80002da8:	67450513          	addi	a0,a0,1652 # 80008418 <states.1748+0x150>
    80002dac:	ffffd097          	auipc	ra,0xffffd
    80002db0:	7e2080e7          	jalr	2018(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002db4:	6cbc                	ld	a5,88(s1)
    80002db6:	577d                	li	a4,-1
    80002db8:	fbb8                	sd	a4,112(a5)
  }
}
    80002dba:	60e2                	ld	ra,24(sp)
    80002dbc:	6442                	ld	s0,16(sp)
    80002dbe:	64a2                	ld	s1,8(sp)
    80002dc0:	6902                	ld	s2,0(sp)
    80002dc2:	6105                	addi	sp,sp,32
    80002dc4:	8082                	ret

0000000080002dc6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"
// added comment commit check
uint64
sys_exit(void)
{
    80002dc6:	1101                	addi	sp,sp,-32
    80002dc8:	ec06                	sd	ra,24(sp)
    80002dca:	e822                	sd	s0,16(sp)
    80002dcc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dce:	fec40593          	addi	a1,s0,-20
    80002dd2:	4501                	li	a0,0
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	f0e080e7          	jalr	-242(ra) # 80002ce2 <argint>
  exit(n);
    80002ddc:	fec42503          	lw	a0,-20(s0)
    80002de0:	fffff097          	auipc	ra,0xfffff
    80002de4:	3be080e7          	jalr	958(ra) # 8000219e <exit>
  return 0;  // not reached
}
    80002de8:	4501                	li	a0,0
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	6105                	addi	sp,sp,32
    80002df0:	8082                	ret

0000000080002df2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002df2:	1141                	addi	sp,sp,-16
    80002df4:	e406                	sd	ra,8(sp)
    80002df6:	e022                	sd	s0,0(sp)
    80002df8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dfa:	fffff097          	auipc	ra,0xfffff
    80002dfe:	bcc080e7          	jalr	-1076(ra) # 800019c6 <myproc>
}
    80002e02:	5908                	lw	a0,48(a0)
    80002e04:	60a2                	ld	ra,8(sp)
    80002e06:	6402                	ld	s0,0(sp)
    80002e08:	0141                	addi	sp,sp,16
    80002e0a:	8082                	ret

0000000080002e0c <sys_fork>:

uint64
sys_fork(void)
{
    80002e0c:	1141                	addi	sp,sp,-16
    80002e0e:	e406                	sd	ra,8(sp)
    80002e10:	e022                	sd	s0,0(sp)
    80002e12:	0800                	addi	s0,sp,16
  return fork();
    80002e14:	fffff097          	auipc	ra,0xfffff
    80002e18:	f68080e7          	jalr	-152(ra) # 80001d7c <fork>
}
    80002e1c:	60a2                	ld	ra,8(sp)
    80002e1e:	6402                	ld	s0,0(sp)
    80002e20:	0141                	addi	sp,sp,16
    80002e22:	8082                	ret

0000000080002e24 <sys_forkn>:

#define MAX_CHILDREN 16

uint64 
sys_forkn(void) 
{
    80002e24:	7119                	addi	sp,sp,-128
    80002e26:	fc86                	sd	ra,120(sp)
    80002e28:	f8a2                	sd	s0,112(sp)
    80002e2a:	f4a6                	sd	s1,104(sp)
    80002e2c:	f0ca                	sd	s2,96(sp)
    80002e2e:	ecce                	sd	s3,88(sp)
    80002e30:	e8d2                	sd	s4,80(sp)
    80002e32:	0100                	addi	s0,sp,128
    int n;
    uint64 pids;  // Userspace pointer for child PIDs
    argint(0, &n);
    80002e34:	fcc40593          	addi	a1,s0,-52
    80002e38:	4501                	li	a0,0
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	ea8080e7          	jalr	-344(ra) # 80002ce2 <argint>
    argaddr(1, &pids);
    80002e42:	fc040593          	addi	a1,s0,-64
    80002e46:	4505                	li	a0,1
    80002e48:	00000097          	auipc	ra,0x0
    80002e4c:	eba080e7          	jalr	-326(ra) # 80002d02 <argaddr>
    // if (n != 0 || pids != 0) {
    //     return -1; // Invalid arguments
    // }

    if (n < 1 || n > MAX_CHILDREN) {
    80002e50:	fcc42783          	lw	a5,-52(s0)
    80002e54:	37fd                	addiw	a5,a5,-1
    80002e56:	473d                	li	a4,15
        return -1; // Restrict range of child processes
    80002e58:	557d                	li	a0,-1
    if (n < 1 || n > MAX_CHILDREN) {
    80002e5a:	04f76863          	bltu	a4,a5,80002eaa <sys_forkn+0x86>

    int created = 0;
    int child_pids[MAX_CHILDREN];

    // Fork n child processes
    for (int i = 0; i < n; i++) {
    80002e5e:	f8040a13          	addi	s4,s0,-128
    if (n < 1 || n > MAX_CHILDREN) {
    80002e62:	8952                	mv	s2,s4
    int created = 0;
    80002e64:	4481                	li	s1,0
    80002e66:	0004899b          	sext.w	s3,s1
        int pid = fork();
    80002e6a:	fffff097          	auipc	ra,0xfffff
    80002e6e:	f12080e7          	jalr	-238(ra) # 80001d7c <fork>
        if (pid < 0) {
    80002e72:	04054463          	bltz	a0,80002eba <sys_forkn+0x96>
            // Cleanup: Kill already created processes
            for (int j = 0; j < created; j++) {
                kill(child_pids[j]);
            }
            return -1;  // Indicate failure
        } else if (pid == 0) {
    80002e76:	c53d                	beqz	a0,80002ee4 <sys_forkn+0xc0>
            return i + 1;  // Child returns its index (1-based)
        }
        child_pids[created++] = pid;
    80002e78:	2485                	addiw	s1,s1,1
    80002e7a:	00a92023          	sw	a0,0(s2)
    for (int i = 0; i < n; i++) {
    80002e7e:	0911                	addi	s2,s2,4
    80002e80:	fcc42783          	lw	a5,-52(s0)
    80002e84:	fef4c1e3          	blt	s1,a5,80002e66 <sys_forkn+0x42>
    }

    // Copy child PIDs to userspace
    if (copyout(myproc()->pagetable, pids, (char *)child_pids, sizeof(int) * n) < 0) {
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	b3e080e7          	jalr	-1218(ra) # 800019c6 <myproc>
    80002e90:	fcc42683          	lw	a3,-52(s0)
    80002e94:	068a                	slli	a3,a3,0x2
    80002e96:	f8040613          	addi	a2,s0,-128
    80002e9a:	fc043583          	ld	a1,-64(s0)
    80002e9e:	6928                	ld	a0,80(a0)
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	7e4080e7          	jalr	2020(ra) # 80001684 <copyout>
    80002ea8:	957d                	srai	a0,a0,0x3f
        return -1;
    }

    return 0; // Success, parent returns 0
}
    80002eaa:	70e6                	ld	ra,120(sp)
    80002eac:	7446                	ld	s0,112(sp)
    80002eae:	74a6                	ld	s1,104(sp)
    80002eb0:	7906                	ld	s2,96(sp)
    80002eb2:	69e6                	ld	s3,88(sp)
    80002eb4:	6a46                	ld	s4,80(sp)
    80002eb6:	6109                	addi	sp,sp,128
    80002eb8:	8082                	ret
            for (int j = 0; j < created; j++) {
    80002eba:	02905863          	blez	s1,80002eea <sys_forkn+0xc6>
    80002ebe:	fff9849b          	addiw	s1,s3,-1
    80002ec2:	1482                	slli	s1,s1,0x20
    80002ec4:	9081                	srli	s1,s1,0x20
    80002ec6:	048a                	slli	s1,s1,0x2
    80002ec8:	004a0793          	addi	a5,s4,4
    80002ecc:	94be                	add	s1,s1,a5
                kill(child_pids[j]);
    80002ece:	000a2503          	lw	a0,0(s4)
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	3a2080e7          	jalr	930(ra) # 80002274 <kill>
            for (int j = 0; j < created; j++) {
    80002eda:	0a11                	addi	s4,s4,4
    80002edc:	fe9a19e3          	bne	s4,s1,80002ece <sys_forkn+0xaa>
            return -1;  // Indicate failure
    80002ee0:	557d                	li	a0,-1
    80002ee2:	b7e1                	j	80002eaa <sys_forkn+0x86>
            return i + 1;  // Child returns its index (1-based)
    80002ee4:	0014851b          	addiw	a0,s1,1
    80002ee8:	b7c9                	j	80002eaa <sys_forkn+0x86>
            return -1;  // Indicate failure
    80002eea:	557d                	li	a0,-1
    80002eec:	bf7d                	j	80002eaa <sys_forkn+0x86>

0000000080002eee <sys_wait>:


uint64
sys_wait(void)
{
    80002eee:	1101                	addi	sp,sp,-32
    80002ef0:	ec06                	sd	ra,24(sp)
    80002ef2:	e822                	sd	s0,16(sp)
    80002ef4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ef6:	fe840593          	addi	a1,s0,-24
    80002efa:	4501                	li	a0,0
    80002efc:	00000097          	auipc	ra,0x0
    80002f00:	e06080e7          	jalr	-506(ra) # 80002d02 <argaddr>
  return wait(p);
    80002f04:	fe843503          	ld	a0,-24(s0)
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	43c080e7          	jalr	1084(ra) # 80002344 <wait>
}
    80002f10:	60e2                	ld	ra,24(sp)
    80002f12:	6442                	ld	s0,16(sp)
    80002f14:	6105                	addi	sp,sp,32
    80002f16:	8082                	ret

0000000080002f18 <sys_waitall>:

uint64
sys_waitall(void) // added
{
    80002f18:	1101                	addi	sp,sp,-32
    80002f1a:	ec06                	sd	ra,24(sp)
    80002f1c:	e822                	sd	s0,16(sp)
    80002f1e:	1000                	addi	s0,sp,32
  uint64 p; 
  uint64 statuses; 
  
  argaddr(0, &p);
    80002f20:	fe840593          	addi	a1,s0,-24
    80002f24:	4501                	li	a0,0
    80002f26:	00000097          	auipc	ra,0x0
    80002f2a:	ddc080e7          	jalr	-548(ra) # 80002d02 <argaddr>
  argaddr(1, &statuses);
    80002f2e:	fe040593          	addi	a1,s0,-32
    80002f32:	4505                	li	a0,1
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	dce080e7          	jalr	-562(ra) # 80002d02 <argaddr>
  
  return waitall(p ,statuses);
    80002f3c:	fe043583          	ld	a1,-32(s0)
    80002f40:	fe843503          	ld	a0,-24(s0)
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	52e080e7          	jalr	1326(ra) # 80002472 <waitall>
}
    80002f4c:	60e2                	ld	ra,24(sp)
    80002f4e:	6442                	ld	s0,16(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret

0000000080002f54 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f54:	7179                	addi	sp,sp,-48
    80002f56:	f406                	sd	ra,40(sp)
    80002f58:	f022                	sd	s0,32(sp)
    80002f5a:	ec26                	sd	s1,24(sp)
    80002f5c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f5e:	fdc40593          	addi	a1,s0,-36
    80002f62:	4501                	li	a0,0
    80002f64:	00000097          	auipc	ra,0x0
    80002f68:	d7e080e7          	jalr	-642(ra) # 80002ce2 <argint>
  addr = myproc()->sz;
    80002f6c:	fffff097          	auipc	ra,0xfffff
    80002f70:	a5a080e7          	jalr	-1446(ra) # 800019c6 <myproc>
    80002f74:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002f76:	fdc42503          	lw	a0,-36(s0)
    80002f7a:	fffff097          	auipc	ra,0xfffff
    80002f7e:	da6080e7          	jalr	-602(ra) # 80001d20 <growproc>
    80002f82:	00054863          	bltz	a0,80002f92 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002f86:	8526                	mv	a0,s1
    80002f88:	70a2                	ld	ra,40(sp)
    80002f8a:	7402                	ld	s0,32(sp)
    80002f8c:	64e2                	ld	s1,24(sp)
    80002f8e:	6145                	addi	sp,sp,48
    80002f90:	8082                	ret
    return -1;
    80002f92:	54fd                	li	s1,-1
    80002f94:	bfcd                	j	80002f86 <sys_sbrk+0x32>

0000000080002f96 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002f96:	7139                	addi	sp,sp,-64
    80002f98:	fc06                	sd	ra,56(sp)
    80002f9a:	f822                	sd	s0,48(sp)
    80002f9c:	f426                	sd	s1,40(sp)
    80002f9e:	f04a                	sd	s2,32(sp)
    80002fa0:	ec4e                	sd	s3,24(sp)
    80002fa2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fa4:	fcc40593          	addi	a1,s0,-52
    80002fa8:	4501                	li	a0,0
    80002faa:	00000097          	auipc	ra,0x0
    80002fae:	d38080e7          	jalr	-712(ra) # 80002ce2 <argint>
  acquire(&tickslock);
    80002fb2:	00014517          	auipc	a0,0x14
    80002fb6:	9be50513          	addi	a0,a0,-1602 # 80016970 <tickslock>
    80002fba:	ffffe097          	auipc	ra,0xffffe
    80002fbe:	c30080e7          	jalr	-976(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002fc2:	00006917          	auipc	s2,0x6
    80002fc6:	90e92903          	lw	s2,-1778(s2) # 800088d0 <ticks>
  while(ticks - ticks0 < n){
    80002fca:	fcc42783          	lw	a5,-52(s0)
    80002fce:	cf9d                	beqz	a5,8000300c <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002fd0:	00014997          	auipc	s3,0x14
    80002fd4:	9a098993          	addi	s3,s3,-1632 # 80016970 <tickslock>
    80002fd8:	00006497          	auipc	s1,0x6
    80002fdc:	8f848493          	addi	s1,s1,-1800 # 800088d0 <ticks>
    if(killed(myproc())){
    80002fe0:	fffff097          	auipc	ra,0xfffff
    80002fe4:	9e6080e7          	jalr	-1562(ra) # 800019c6 <myproc>
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	32a080e7          	jalr	810(ra) # 80002312 <killed>
    80002ff0:	ed15                	bnez	a0,8000302c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ff2:	85ce                	mv	a1,s3
    80002ff4:	8526                	mv	a0,s1
    80002ff6:	fffff097          	auipc	ra,0xfffff
    80002ffa:	074080e7          	jalr	116(ra) # 8000206a <sleep>
  while(ticks - ticks0 < n){
    80002ffe:	409c                	lw	a5,0(s1)
    80003000:	412787bb          	subw	a5,a5,s2
    80003004:	fcc42703          	lw	a4,-52(s0)
    80003008:	fce7ece3          	bltu	a5,a4,80002fe0 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000300c:	00014517          	auipc	a0,0x14
    80003010:	96450513          	addi	a0,a0,-1692 # 80016970 <tickslock>
    80003014:	ffffe097          	auipc	ra,0xffffe
    80003018:	c8a080e7          	jalr	-886(ra) # 80000c9e <release>
  return 0;
    8000301c:	4501                	li	a0,0
}
    8000301e:	70e2                	ld	ra,56(sp)
    80003020:	7442                	ld	s0,48(sp)
    80003022:	74a2                	ld	s1,40(sp)
    80003024:	7902                	ld	s2,32(sp)
    80003026:	69e2                	ld	s3,24(sp)
    80003028:	6121                	addi	sp,sp,64
    8000302a:	8082                	ret
      release(&tickslock);
    8000302c:	00014517          	auipc	a0,0x14
    80003030:	94450513          	addi	a0,a0,-1724 # 80016970 <tickslock>
    80003034:	ffffe097          	auipc	ra,0xffffe
    80003038:	c6a080e7          	jalr	-918(ra) # 80000c9e <release>
      return -1;
    8000303c:	557d                	li	a0,-1
    8000303e:	b7c5                	j	8000301e <sys_sleep+0x88>

0000000080003040 <sys_kill>:

uint64
sys_kill(void)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003048:	fec40593          	addi	a1,s0,-20
    8000304c:	4501                	li	a0,0
    8000304e:	00000097          	auipc	ra,0x0
    80003052:	c94080e7          	jalr	-876(ra) # 80002ce2 <argint>
  return kill(pid);
    80003056:	fec42503          	lw	a0,-20(s0)
    8000305a:	fffff097          	auipc	ra,0xfffff
    8000305e:	21a080e7          	jalr	538(ra) # 80002274 <kill>
}
    80003062:	60e2                	ld	ra,24(sp)
    80003064:	6442                	ld	s0,16(sp)
    80003066:	6105                	addi	sp,sp,32
    80003068:	8082                	ret

000000008000306a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000306a:	1101                	addi	sp,sp,-32
    8000306c:	ec06                	sd	ra,24(sp)
    8000306e:	e822                	sd	s0,16(sp)
    80003070:	e426                	sd	s1,8(sp)
    80003072:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003074:	00014517          	auipc	a0,0x14
    80003078:	8fc50513          	addi	a0,a0,-1796 # 80016970 <tickslock>
    8000307c:	ffffe097          	auipc	ra,0xffffe
    80003080:	b6e080e7          	jalr	-1170(ra) # 80000bea <acquire>
  xticks = ticks;
    80003084:	00006497          	auipc	s1,0x6
    80003088:	84c4a483          	lw	s1,-1972(s1) # 800088d0 <ticks>
  release(&tickslock);
    8000308c:	00014517          	auipc	a0,0x14
    80003090:	8e450513          	addi	a0,a0,-1820 # 80016970 <tickslock>
    80003094:	ffffe097          	auipc	ra,0xffffe
    80003098:	c0a080e7          	jalr	-1014(ra) # 80000c9e <release>
  return xticks;
}
    8000309c:	02049513          	slli	a0,s1,0x20
    800030a0:	9101                	srli	a0,a0,0x20
    800030a2:	60e2                	ld	ra,24(sp)
    800030a4:	6442                	ld	s0,16(sp)
    800030a6:	64a2                	ld	s1,8(sp)
    800030a8:	6105                	addi	sp,sp,32
    800030aa:	8082                	ret

00000000800030ac <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030ac:	7179                	addi	sp,sp,-48
    800030ae:	f406                	sd	ra,40(sp)
    800030b0:	f022                	sd	s0,32(sp)
    800030b2:	ec26                	sd	s1,24(sp)
    800030b4:	e84a                	sd	s2,16(sp)
    800030b6:	e44e                	sd	s3,8(sp)
    800030b8:	e052                	sd	s4,0(sp)
    800030ba:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030bc:	00005597          	auipc	a1,0x5
    800030c0:	45458593          	addi	a1,a1,1108 # 80008510 <syscalls+0xc0>
    800030c4:	00014517          	auipc	a0,0x14
    800030c8:	8c450513          	addi	a0,a0,-1852 # 80016988 <bcache>
    800030cc:	ffffe097          	auipc	ra,0xffffe
    800030d0:	a8e080e7          	jalr	-1394(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030d4:	0001c797          	auipc	a5,0x1c
    800030d8:	8b478793          	addi	a5,a5,-1868 # 8001e988 <bcache+0x8000>
    800030dc:	0001c717          	auipc	a4,0x1c
    800030e0:	b1470713          	addi	a4,a4,-1260 # 8001ebf0 <bcache+0x8268>
    800030e4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030e8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030ec:	00014497          	auipc	s1,0x14
    800030f0:	8b448493          	addi	s1,s1,-1868 # 800169a0 <bcache+0x18>
    b->next = bcache.head.next;
    800030f4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030f6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030f8:	00005a17          	auipc	s4,0x5
    800030fc:	420a0a13          	addi	s4,s4,1056 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003100:	2b893783          	ld	a5,696(s2)
    80003104:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003106:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000310a:	85d2                	mv	a1,s4
    8000310c:	01048513          	addi	a0,s1,16
    80003110:	00001097          	auipc	ra,0x1
    80003114:	4c4080e7          	jalr	1220(ra) # 800045d4 <initsleeplock>
    bcache.head.next->prev = b;
    80003118:	2b893783          	ld	a5,696(s2)
    8000311c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000311e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003122:	45848493          	addi	s1,s1,1112
    80003126:	fd349de3          	bne	s1,s3,80003100 <binit+0x54>
  }
}
    8000312a:	70a2                	ld	ra,40(sp)
    8000312c:	7402                	ld	s0,32(sp)
    8000312e:	64e2                	ld	s1,24(sp)
    80003130:	6942                	ld	s2,16(sp)
    80003132:	69a2                	ld	s3,8(sp)
    80003134:	6a02                	ld	s4,0(sp)
    80003136:	6145                	addi	sp,sp,48
    80003138:	8082                	ret

000000008000313a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000313a:	7179                	addi	sp,sp,-48
    8000313c:	f406                	sd	ra,40(sp)
    8000313e:	f022                	sd	s0,32(sp)
    80003140:	ec26                	sd	s1,24(sp)
    80003142:	e84a                	sd	s2,16(sp)
    80003144:	e44e                	sd	s3,8(sp)
    80003146:	1800                	addi	s0,sp,48
    80003148:	89aa                	mv	s3,a0
    8000314a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000314c:	00014517          	auipc	a0,0x14
    80003150:	83c50513          	addi	a0,a0,-1988 # 80016988 <bcache>
    80003154:	ffffe097          	auipc	ra,0xffffe
    80003158:	a96080e7          	jalr	-1386(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000315c:	0001c497          	auipc	s1,0x1c
    80003160:	ae44b483          	ld	s1,-1308(s1) # 8001ec40 <bcache+0x82b8>
    80003164:	0001c797          	auipc	a5,0x1c
    80003168:	a8c78793          	addi	a5,a5,-1396 # 8001ebf0 <bcache+0x8268>
    8000316c:	02f48f63          	beq	s1,a5,800031aa <bread+0x70>
    80003170:	873e                	mv	a4,a5
    80003172:	a021                	j	8000317a <bread+0x40>
    80003174:	68a4                	ld	s1,80(s1)
    80003176:	02e48a63          	beq	s1,a4,800031aa <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000317a:	449c                	lw	a5,8(s1)
    8000317c:	ff379ce3          	bne	a5,s3,80003174 <bread+0x3a>
    80003180:	44dc                	lw	a5,12(s1)
    80003182:	ff2799e3          	bne	a5,s2,80003174 <bread+0x3a>
      b->refcnt++;
    80003186:	40bc                	lw	a5,64(s1)
    80003188:	2785                	addiw	a5,a5,1
    8000318a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000318c:	00013517          	auipc	a0,0x13
    80003190:	7fc50513          	addi	a0,a0,2044 # 80016988 <bcache>
    80003194:	ffffe097          	auipc	ra,0xffffe
    80003198:	b0a080e7          	jalr	-1270(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000319c:	01048513          	addi	a0,s1,16
    800031a0:	00001097          	auipc	ra,0x1
    800031a4:	46e080e7          	jalr	1134(ra) # 8000460e <acquiresleep>
      return b;
    800031a8:	a8b9                	j	80003206 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031aa:	0001c497          	auipc	s1,0x1c
    800031ae:	a8e4b483          	ld	s1,-1394(s1) # 8001ec38 <bcache+0x82b0>
    800031b2:	0001c797          	auipc	a5,0x1c
    800031b6:	a3e78793          	addi	a5,a5,-1474 # 8001ebf0 <bcache+0x8268>
    800031ba:	00f48863          	beq	s1,a5,800031ca <bread+0x90>
    800031be:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031c0:	40bc                	lw	a5,64(s1)
    800031c2:	cf81                	beqz	a5,800031da <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031c4:	64a4                	ld	s1,72(s1)
    800031c6:	fee49de3          	bne	s1,a4,800031c0 <bread+0x86>
  panic("bget: no buffers");
    800031ca:	00005517          	auipc	a0,0x5
    800031ce:	35650513          	addi	a0,a0,854 # 80008520 <syscalls+0xd0>
    800031d2:	ffffd097          	auipc	ra,0xffffd
    800031d6:	372080e7          	jalr	882(ra) # 80000544 <panic>
      b->dev = dev;
    800031da:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031de:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031e2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031e6:	4785                	li	a5,1
    800031e8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ea:	00013517          	auipc	a0,0x13
    800031ee:	79e50513          	addi	a0,a0,1950 # 80016988 <bcache>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	aac080e7          	jalr	-1364(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800031fa:	01048513          	addi	a0,s1,16
    800031fe:	00001097          	auipc	ra,0x1
    80003202:	410080e7          	jalr	1040(ra) # 8000460e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003206:	409c                	lw	a5,0(s1)
    80003208:	cb89                	beqz	a5,8000321a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000320a:	8526                	mv	a0,s1
    8000320c:	70a2                	ld	ra,40(sp)
    8000320e:	7402                	ld	s0,32(sp)
    80003210:	64e2                	ld	s1,24(sp)
    80003212:	6942                	ld	s2,16(sp)
    80003214:	69a2                	ld	s3,8(sp)
    80003216:	6145                	addi	sp,sp,48
    80003218:	8082                	ret
    virtio_disk_rw(b, 0);
    8000321a:	4581                	li	a1,0
    8000321c:	8526                	mv	a0,s1
    8000321e:	00003097          	auipc	ra,0x3
    80003222:	fca080e7          	jalr	-54(ra) # 800061e8 <virtio_disk_rw>
    b->valid = 1;
    80003226:	4785                	li	a5,1
    80003228:	c09c                	sw	a5,0(s1)
  return b;
    8000322a:	b7c5                	j	8000320a <bread+0xd0>

000000008000322c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000322c:	1101                	addi	sp,sp,-32
    8000322e:	ec06                	sd	ra,24(sp)
    80003230:	e822                	sd	s0,16(sp)
    80003232:	e426                	sd	s1,8(sp)
    80003234:	1000                	addi	s0,sp,32
    80003236:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003238:	0541                	addi	a0,a0,16
    8000323a:	00001097          	auipc	ra,0x1
    8000323e:	46e080e7          	jalr	1134(ra) # 800046a8 <holdingsleep>
    80003242:	cd01                	beqz	a0,8000325a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003244:	4585                	li	a1,1
    80003246:	8526                	mv	a0,s1
    80003248:	00003097          	auipc	ra,0x3
    8000324c:	fa0080e7          	jalr	-96(ra) # 800061e8 <virtio_disk_rw>
}
    80003250:	60e2                	ld	ra,24(sp)
    80003252:	6442                	ld	s0,16(sp)
    80003254:	64a2                	ld	s1,8(sp)
    80003256:	6105                	addi	sp,sp,32
    80003258:	8082                	ret
    panic("bwrite");
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	2de50513          	addi	a0,a0,734 # 80008538 <syscalls+0xe8>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	2e2080e7          	jalr	738(ra) # 80000544 <panic>

000000008000326a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000326a:	1101                	addi	sp,sp,-32
    8000326c:	ec06                	sd	ra,24(sp)
    8000326e:	e822                	sd	s0,16(sp)
    80003270:	e426                	sd	s1,8(sp)
    80003272:	e04a                	sd	s2,0(sp)
    80003274:	1000                	addi	s0,sp,32
    80003276:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003278:	01050913          	addi	s2,a0,16
    8000327c:	854a                	mv	a0,s2
    8000327e:	00001097          	auipc	ra,0x1
    80003282:	42a080e7          	jalr	1066(ra) # 800046a8 <holdingsleep>
    80003286:	c92d                	beqz	a0,800032f8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003288:	854a                	mv	a0,s2
    8000328a:	00001097          	auipc	ra,0x1
    8000328e:	3da080e7          	jalr	986(ra) # 80004664 <releasesleep>

  acquire(&bcache.lock);
    80003292:	00013517          	auipc	a0,0x13
    80003296:	6f650513          	addi	a0,a0,1782 # 80016988 <bcache>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	950080e7          	jalr	-1712(ra) # 80000bea <acquire>
  b->refcnt--;
    800032a2:	40bc                	lw	a5,64(s1)
    800032a4:	37fd                	addiw	a5,a5,-1
    800032a6:	0007871b          	sext.w	a4,a5
    800032aa:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032ac:	eb05                	bnez	a4,800032dc <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032ae:	68bc                	ld	a5,80(s1)
    800032b0:	64b8                	ld	a4,72(s1)
    800032b2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032b4:	64bc                	ld	a5,72(s1)
    800032b6:	68b8                	ld	a4,80(s1)
    800032b8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032ba:	0001b797          	auipc	a5,0x1b
    800032be:	6ce78793          	addi	a5,a5,1742 # 8001e988 <bcache+0x8000>
    800032c2:	2b87b703          	ld	a4,696(a5)
    800032c6:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032c8:	0001c717          	auipc	a4,0x1c
    800032cc:	92870713          	addi	a4,a4,-1752 # 8001ebf0 <bcache+0x8268>
    800032d0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032d2:	2b87b703          	ld	a4,696(a5)
    800032d6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032d8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032dc:	00013517          	auipc	a0,0x13
    800032e0:	6ac50513          	addi	a0,a0,1708 # 80016988 <bcache>
    800032e4:	ffffe097          	auipc	ra,0xffffe
    800032e8:	9ba080e7          	jalr	-1606(ra) # 80000c9e <release>
}
    800032ec:	60e2                	ld	ra,24(sp)
    800032ee:	6442                	ld	s0,16(sp)
    800032f0:	64a2                	ld	s1,8(sp)
    800032f2:	6902                	ld	s2,0(sp)
    800032f4:	6105                	addi	sp,sp,32
    800032f6:	8082                	ret
    panic("brelse");
    800032f8:	00005517          	auipc	a0,0x5
    800032fc:	24850513          	addi	a0,a0,584 # 80008540 <syscalls+0xf0>
    80003300:	ffffd097          	auipc	ra,0xffffd
    80003304:	244080e7          	jalr	580(ra) # 80000544 <panic>

0000000080003308 <bpin>:

void
bpin(struct buf *b) {
    80003308:	1101                	addi	sp,sp,-32
    8000330a:	ec06                	sd	ra,24(sp)
    8000330c:	e822                	sd	s0,16(sp)
    8000330e:	e426                	sd	s1,8(sp)
    80003310:	1000                	addi	s0,sp,32
    80003312:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003314:	00013517          	auipc	a0,0x13
    80003318:	67450513          	addi	a0,a0,1652 # 80016988 <bcache>
    8000331c:	ffffe097          	auipc	ra,0xffffe
    80003320:	8ce080e7          	jalr	-1842(ra) # 80000bea <acquire>
  b->refcnt++;
    80003324:	40bc                	lw	a5,64(s1)
    80003326:	2785                	addiw	a5,a5,1
    80003328:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000332a:	00013517          	auipc	a0,0x13
    8000332e:	65e50513          	addi	a0,a0,1630 # 80016988 <bcache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	96c080e7          	jalr	-1684(ra) # 80000c9e <release>
}
    8000333a:	60e2                	ld	ra,24(sp)
    8000333c:	6442                	ld	s0,16(sp)
    8000333e:	64a2                	ld	s1,8(sp)
    80003340:	6105                	addi	sp,sp,32
    80003342:	8082                	ret

0000000080003344 <bunpin>:

void
bunpin(struct buf *b) {
    80003344:	1101                	addi	sp,sp,-32
    80003346:	ec06                	sd	ra,24(sp)
    80003348:	e822                	sd	s0,16(sp)
    8000334a:	e426                	sd	s1,8(sp)
    8000334c:	1000                	addi	s0,sp,32
    8000334e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003350:	00013517          	auipc	a0,0x13
    80003354:	63850513          	addi	a0,a0,1592 # 80016988 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	892080e7          	jalr	-1902(ra) # 80000bea <acquire>
  b->refcnt--;
    80003360:	40bc                	lw	a5,64(s1)
    80003362:	37fd                	addiw	a5,a5,-1
    80003364:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003366:	00013517          	auipc	a0,0x13
    8000336a:	62250513          	addi	a0,a0,1570 # 80016988 <bcache>
    8000336e:	ffffe097          	auipc	ra,0xffffe
    80003372:	930080e7          	jalr	-1744(ra) # 80000c9e <release>
}
    80003376:	60e2                	ld	ra,24(sp)
    80003378:	6442                	ld	s0,16(sp)
    8000337a:	64a2                	ld	s1,8(sp)
    8000337c:	6105                	addi	sp,sp,32
    8000337e:	8082                	ret

0000000080003380 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003380:	1101                	addi	sp,sp,-32
    80003382:	ec06                	sd	ra,24(sp)
    80003384:	e822                	sd	s0,16(sp)
    80003386:	e426                	sd	s1,8(sp)
    80003388:	e04a                	sd	s2,0(sp)
    8000338a:	1000                	addi	s0,sp,32
    8000338c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000338e:	00d5d59b          	srliw	a1,a1,0xd
    80003392:	0001c797          	auipc	a5,0x1c
    80003396:	cd27a783          	lw	a5,-814(a5) # 8001f064 <sb+0x1c>
    8000339a:	9dbd                	addw	a1,a1,a5
    8000339c:	00000097          	auipc	ra,0x0
    800033a0:	d9e080e7          	jalr	-610(ra) # 8000313a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033a4:	0074f713          	andi	a4,s1,7
    800033a8:	4785                	li	a5,1
    800033aa:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033ae:	14ce                	slli	s1,s1,0x33
    800033b0:	90d9                	srli	s1,s1,0x36
    800033b2:	00950733          	add	a4,a0,s1
    800033b6:	05874703          	lbu	a4,88(a4)
    800033ba:	00e7f6b3          	and	a3,a5,a4
    800033be:	c69d                	beqz	a3,800033ec <bfree+0x6c>
    800033c0:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033c2:	94aa                	add	s1,s1,a0
    800033c4:	fff7c793          	not	a5,a5
    800033c8:	8ff9                	and	a5,a5,a4
    800033ca:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033ce:	00001097          	auipc	ra,0x1
    800033d2:	120080e7          	jalr	288(ra) # 800044ee <log_write>
  brelse(bp);
    800033d6:	854a                	mv	a0,s2
    800033d8:	00000097          	auipc	ra,0x0
    800033dc:	e92080e7          	jalr	-366(ra) # 8000326a <brelse>
}
    800033e0:	60e2                	ld	ra,24(sp)
    800033e2:	6442                	ld	s0,16(sp)
    800033e4:	64a2                	ld	s1,8(sp)
    800033e6:	6902                	ld	s2,0(sp)
    800033e8:	6105                	addi	sp,sp,32
    800033ea:	8082                	ret
    panic("freeing free block");
    800033ec:	00005517          	auipc	a0,0x5
    800033f0:	15c50513          	addi	a0,a0,348 # 80008548 <syscalls+0xf8>
    800033f4:	ffffd097          	auipc	ra,0xffffd
    800033f8:	150080e7          	jalr	336(ra) # 80000544 <panic>

00000000800033fc <balloc>:
{
    800033fc:	711d                	addi	sp,sp,-96
    800033fe:	ec86                	sd	ra,88(sp)
    80003400:	e8a2                	sd	s0,80(sp)
    80003402:	e4a6                	sd	s1,72(sp)
    80003404:	e0ca                	sd	s2,64(sp)
    80003406:	fc4e                	sd	s3,56(sp)
    80003408:	f852                	sd	s4,48(sp)
    8000340a:	f456                	sd	s5,40(sp)
    8000340c:	f05a                	sd	s6,32(sp)
    8000340e:	ec5e                	sd	s7,24(sp)
    80003410:	e862                	sd	s8,16(sp)
    80003412:	e466                	sd	s9,8(sp)
    80003414:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003416:	0001c797          	auipc	a5,0x1c
    8000341a:	c367a783          	lw	a5,-970(a5) # 8001f04c <sb+0x4>
    8000341e:	10078163          	beqz	a5,80003520 <balloc+0x124>
    80003422:	8baa                	mv	s7,a0
    80003424:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003426:	0001cb17          	auipc	s6,0x1c
    8000342a:	c22b0b13          	addi	s6,s6,-990 # 8001f048 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000342e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003430:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003432:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003434:	6c89                	lui	s9,0x2
    80003436:	a061                	j	800034be <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003438:	974a                	add	a4,a4,s2
    8000343a:	8fd5                	or	a5,a5,a3
    8000343c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003440:	854a                	mv	a0,s2
    80003442:	00001097          	auipc	ra,0x1
    80003446:	0ac080e7          	jalr	172(ra) # 800044ee <log_write>
        brelse(bp);
    8000344a:	854a                	mv	a0,s2
    8000344c:	00000097          	auipc	ra,0x0
    80003450:	e1e080e7          	jalr	-482(ra) # 8000326a <brelse>
  bp = bread(dev, bno);
    80003454:	85a6                	mv	a1,s1
    80003456:	855e                	mv	a0,s7
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	ce2080e7          	jalr	-798(ra) # 8000313a <bread>
    80003460:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003462:	40000613          	li	a2,1024
    80003466:	4581                	li	a1,0
    80003468:	05850513          	addi	a0,a0,88
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	87a080e7          	jalr	-1926(ra) # 80000ce6 <memset>
  log_write(bp);
    80003474:	854a                	mv	a0,s2
    80003476:	00001097          	auipc	ra,0x1
    8000347a:	078080e7          	jalr	120(ra) # 800044ee <log_write>
  brelse(bp);
    8000347e:	854a                	mv	a0,s2
    80003480:	00000097          	auipc	ra,0x0
    80003484:	dea080e7          	jalr	-534(ra) # 8000326a <brelse>
}
    80003488:	8526                	mv	a0,s1
    8000348a:	60e6                	ld	ra,88(sp)
    8000348c:	6446                	ld	s0,80(sp)
    8000348e:	64a6                	ld	s1,72(sp)
    80003490:	6906                	ld	s2,64(sp)
    80003492:	79e2                	ld	s3,56(sp)
    80003494:	7a42                	ld	s4,48(sp)
    80003496:	7aa2                	ld	s5,40(sp)
    80003498:	7b02                	ld	s6,32(sp)
    8000349a:	6be2                	ld	s7,24(sp)
    8000349c:	6c42                	ld	s8,16(sp)
    8000349e:	6ca2                	ld	s9,8(sp)
    800034a0:	6125                	addi	sp,sp,96
    800034a2:	8082                	ret
    brelse(bp);
    800034a4:	854a                	mv	a0,s2
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	dc4080e7          	jalr	-572(ra) # 8000326a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034ae:	015c87bb          	addw	a5,s9,s5
    800034b2:	00078a9b          	sext.w	s5,a5
    800034b6:	004b2703          	lw	a4,4(s6)
    800034ba:	06eaf363          	bgeu	s5,a4,80003520 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800034be:	41fad79b          	sraiw	a5,s5,0x1f
    800034c2:	0137d79b          	srliw	a5,a5,0x13
    800034c6:	015787bb          	addw	a5,a5,s5
    800034ca:	40d7d79b          	sraiw	a5,a5,0xd
    800034ce:	01cb2583          	lw	a1,28(s6)
    800034d2:	9dbd                	addw	a1,a1,a5
    800034d4:	855e                	mv	a0,s7
    800034d6:	00000097          	auipc	ra,0x0
    800034da:	c64080e7          	jalr	-924(ra) # 8000313a <bread>
    800034de:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034e0:	004b2503          	lw	a0,4(s6)
    800034e4:	000a849b          	sext.w	s1,s5
    800034e8:	8662                	mv	a2,s8
    800034ea:	faa4fde3          	bgeu	s1,a0,800034a4 <balloc+0xa8>
      m = 1 << (bi % 8);
    800034ee:	41f6579b          	sraiw	a5,a2,0x1f
    800034f2:	01d7d69b          	srliw	a3,a5,0x1d
    800034f6:	00c6873b          	addw	a4,a3,a2
    800034fa:	00777793          	andi	a5,a4,7
    800034fe:	9f95                	subw	a5,a5,a3
    80003500:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003504:	4037571b          	sraiw	a4,a4,0x3
    80003508:	00e906b3          	add	a3,s2,a4
    8000350c:	0586c683          	lbu	a3,88(a3)
    80003510:	00d7f5b3          	and	a1,a5,a3
    80003514:	d195                	beqz	a1,80003438 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003516:	2605                	addiw	a2,a2,1
    80003518:	2485                	addiw	s1,s1,1
    8000351a:	fd4618e3          	bne	a2,s4,800034ea <balloc+0xee>
    8000351e:	b759                	j	800034a4 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003520:	00005517          	auipc	a0,0x5
    80003524:	04050513          	addi	a0,a0,64 # 80008560 <syscalls+0x110>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	066080e7          	jalr	102(ra) # 8000058e <printf>
  return 0;
    80003530:	4481                	li	s1,0
    80003532:	bf99                	j	80003488 <balloc+0x8c>

0000000080003534 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003534:	7179                	addi	sp,sp,-48
    80003536:	f406                	sd	ra,40(sp)
    80003538:	f022                	sd	s0,32(sp)
    8000353a:	ec26                	sd	s1,24(sp)
    8000353c:	e84a                	sd	s2,16(sp)
    8000353e:	e44e                	sd	s3,8(sp)
    80003540:	e052                	sd	s4,0(sp)
    80003542:	1800                	addi	s0,sp,48
    80003544:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003546:	47ad                	li	a5,11
    80003548:	02b7e763          	bltu	a5,a1,80003576 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000354c:	02059493          	slli	s1,a1,0x20
    80003550:	9081                	srli	s1,s1,0x20
    80003552:	048a                	slli	s1,s1,0x2
    80003554:	94aa                	add	s1,s1,a0
    80003556:	0504a903          	lw	s2,80(s1)
    8000355a:	06091e63          	bnez	s2,800035d6 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000355e:	4108                	lw	a0,0(a0)
    80003560:	00000097          	auipc	ra,0x0
    80003564:	e9c080e7          	jalr	-356(ra) # 800033fc <balloc>
    80003568:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000356c:	06090563          	beqz	s2,800035d6 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003570:	0524a823          	sw	s2,80(s1)
    80003574:	a08d                	j	800035d6 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003576:	ff45849b          	addiw	s1,a1,-12
    8000357a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000357e:	0ff00793          	li	a5,255
    80003582:	08e7e563          	bltu	a5,a4,8000360c <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003586:	08052903          	lw	s2,128(a0)
    8000358a:	00091d63          	bnez	s2,800035a4 <bmap+0x70>
      addr = balloc(ip->dev);
    8000358e:	4108                	lw	a0,0(a0)
    80003590:	00000097          	auipc	ra,0x0
    80003594:	e6c080e7          	jalr	-404(ra) # 800033fc <balloc>
    80003598:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000359c:	02090d63          	beqz	s2,800035d6 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800035a0:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800035a4:	85ca                	mv	a1,s2
    800035a6:	0009a503          	lw	a0,0(s3)
    800035aa:	00000097          	auipc	ra,0x0
    800035ae:	b90080e7          	jalr	-1136(ra) # 8000313a <bread>
    800035b2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035b4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035b8:	02049593          	slli	a1,s1,0x20
    800035bc:	9181                	srli	a1,a1,0x20
    800035be:	058a                	slli	a1,a1,0x2
    800035c0:	00b784b3          	add	s1,a5,a1
    800035c4:	0004a903          	lw	s2,0(s1)
    800035c8:	02090063          	beqz	s2,800035e8 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035cc:	8552                	mv	a0,s4
    800035ce:	00000097          	auipc	ra,0x0
    800035d2:	c9c080e7          	jalr	-868(ra) # 8000326a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035d6:	854a                	mv	a0,s2
    800035d8:	70a2                	ld	ra,40(sp)
    800035da:	7402                	ld	s0,32(sp)
    800035dc:	64e2                	ld	s1,24(sp)
    800035de:	6942                	ld	s2,16(sp)
    800035e0:	69a2                	ld	s3,8(sp)
    800035e2:	6a02                	ld	s4,0(sp)
    800035e4:	6145                	addi	sp,sp,48
    800035e6:	8082                	ret
      addr = balloc(ip->dev);
    800035e8:	0009a503          	lw	a0,0(s3)
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e10080e7          	jalr	-496(ra) # 800033fc <balloc>
    800035f4:	0005091b          	sext.w	s2,a0
      if(addr){
    800035f8:	fc090ae3          	beqz	s2,800035cc <bmap+0x98>
        a[bn] = addr;
    800035fc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003600:	8552                	mv	a0,s4
    80003602:	00001097          	auipc	ra,0x1
    80003606:	eec080e7          	jalr	-276(ra) # 800044ee <log_write>
    8000360a:	b7c9                	j	800035cc <bmap+0x98>
  panic("bmap: out of range");
    8000360c:	00005517          	auipc	a0,0x5
    80003610:	f6c50513          	addi	a0,a0,-148 # 80008578 <syscalls+0x128>
    80003614:	ffffd097          	auipc	ra,0xffffd
    80003618:	f30080e7          	jalr	-208(ra) # 80000544 <panic>

000000008000361c <iget>:
{
    8000361c:	7179                	addi	sp,sp,-48
    8000361e:	f406                	sd	ra,40(sp)
    80003620:	f022                	sd	s0,32(sp)
    80003622:	ec26                	sd	s1,24(sp)
    80003624:	e84a                	sd	s2,16(sp)
    80003626:	e44e                	sd	s3,8(sp)
    80003628:	e052                	sd	s4,0(sp)
    8000362a:	1800                	addi	s0,sp,48
    8000362c:	89aa                	mv	s3,a0
    8000362e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003630:	0001c517          	auipc	a0,0x1c
    80003634:	a3850513          	addi	a0,a0,-1480 # 8001f068 <itable>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	5b2080e7          	jalr	1458(ra) # 80000bea <acquire>
  empty = 0;
    80003640:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003642:	0001c497          	auipc	s1,0x1c
    80003646:	a3e48493          	addi	s1,s1,-1474 # 8001f080 <itable+0x18>
    8000364a:	0001d697          	auipc	a3,0x1d
    8000364e:	4c668693          	addi	a3,a3,1222 # 80020b10 <log>
    80003652:	a039                	j	80003660 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003654:	02090b63          	beqz	s2,8000368a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003658:	08848493          	addi	s1,s1,136
    8000365c:	02d48a63          	beq	s1,a3,80003690 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003660:	449c                	lw	a5,8(s1)
    80003662:	fef059e3          	blez	a5,80003654 <iget+0x38>
    80003666:	4098                	lw	a4,0(s1)
    80003668:	ff3716e3          	bne	a4,s3,80003654 <iget+0x38>
    8000366c:	40d8                	lw	a4,4(s1)
    8000366e:	ff4713e3          	bne	a4,s4,80003654 <iget+0x38>
      ip->ref++;
    80003672:	2785                	addiw	a5,a5,1
    80003674:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003676:	0001c517          	auipc	a0,0x1c
    8000367a:	9f250513          	addi	a0,a0,-1550 # 8001f068 <itable>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	620080e7          	jalr	1568(ra) # 80000c9e <release>
      return ip;
    80003686:	8926                	mv	s2,s1
    80003688:	a03d                	j	800036b6 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000368a:	f7f9                	bnez	a5,80003658 <iget+0x3c>
    8000368c:	8926                	mv	s2,s1
    8000368e:	b7e9                	j	80003658 <iget+0x3c>
  if(empty == 0)
    80003690:	02090c63          	beqz	s2,800036c8 <iget+0xac>
  ip->dev = dev;
    80003694:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003698:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000369c:	4785                	li	a5,1
    8000369e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036a2:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036a6:	0001c517          	auipc	a0,0x1c
    800036aa:	9c250513          	addi	a0,a0,-1598 # 8001f068 <itable>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	5f0080e7          	jalr	1520(ra) # 80000c9e <release>
}
    800036b6:	854a                	mv	a0,s2
    800036b8:	70a2                	ld	ra,40(sp)
    800036ba:	7402                	ld	s0,32(sp)
    800036bc:	64e2                	ld	s1,24(sp)
    800036be:	6942                	ld	s2,16(sp)
    800036c0:	69a2                	ld	s3,8(sp)
    800036c2:	6a02                	ld	s4,0(sp)
    800036c4:	6145                	addi	sp,sp,48
    800036c6:	8082                	ret
    panic("iget: no inodes");
    800036c8:	00005517          	auipc	a0,0x5
    800036cc:	ec850513          	addi	a0,a0,-312 # 80008590 <syscalls+0x140>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	e74080e7          	jalr	-396(ra) # 80000544 <panic>

00000000800036d8 <fsinit>:
fsinit(int dev) {
    800036d8:	7179                	addi	sp,sp,-48
    800036da:	f406                	sd	ra,40(sp)
    800036dc:	f022                	sd	s0,32(sp)
    800036de:	ec26                	sd	s1,24(sp)
    800036e0:	e84a                	sd	s2,16(sp)
    800036e2:	e44e                	sd	s3,8(sp)
    800036e4:	1800                	addi	s0,sp,48
    800036e6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036e8:	4585                	li	a1,1
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	a50080e7          	jalr	-1456(ra) # 8000313a <bread>
    800036f2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036f4:	0001c997          	auipc	s3,0x1c
    800036f8:	95498993          	addi	s3,s3,-1708 # 8001f048 <sb>
    800036fc:	02000613          	li	a2,32
    80003700:	05850593          	addi	a1,a0,88
    80003704:	854e                	mv	a0,s3
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	640080e7          	jalr	1600(ra) # 80000d46 <memmove>
  brelse(bp);
    8000370e:	8526                	mv	a0,s1
    80003710:	00000097          	auipc	ra,0x0
    80003714:	b5a080e7          	jalr	-1190(ra) # 8000326a <brelse>
  if(sb.magic != FSMAGIC)
    80003718:	0009a703          	lw	a4,0(s3)
    8000371c:	102037b7          	lui	a5,0x10203
    80003720:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003724:	02f71263          	bne	a4,a5,80003748 <fsinit+0x70>
  initlog(dev, &sb);
    80003728:	0001c597          	auipc	a1,0x1c
    8000372c:	92058593          	addi	a1,a1,-1760 # 8001f048 <sb>
    80003730:	854a                	mv	a0,s2
    80003732:	00001097          	auipc	ra,0x1
    80003736:	b40080e7          	jalr	-1216(ra) # 80004272 <initlog>
}
    8000373a:	70a2                	ld	ra,40(sp)
    8000373c:	7402                	ld	s0,32(sp)
    8000373e:	64e2                	ld	s1,24(sp)
    80003740:	6942                	ld	s2,16(sp)
    80003742:	69a2                	ld	s3,8(sp)
    80003744:	6145                	addi	sp,sp,48
    80003746:	8082                	ret
    panic("invalid file system");
    80003748:	00005517          	auipc	a0,0x5
    8000374c:	e5850513          	addi	a0,a0,-424 # 800085a0 <syscalls+0x150>
    80003750:	ffffd097          	auipc	ra,0xffffd
    80003754:	df4080e7          	jalr	-524(ra) # 80000544 <panic>

0000000080003758 <iinit>:
{
    80003758:	7179                	addi	sp,sp,-48
    8000375a:	f406                	sd	ra,40(sp)
    8000375c:	f022                	sd	s0,32(sp)
    8000375e:	ec26                	sd	s1,24(sp)
    80003760:	e84a                	sd	s2,16(sp)
    80003762:	e44e                	sd	s3,8(sp)
    80003764:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003766:	00005597          	auipc	a1,0x5
    8000376a:	e5258593          	addi	a1,a1,-430 # 800085b8 <syscalls+0x168>
    8000376e:	0001c517          	auipc	a0,0x1c
    80003772:	8fa50513          	addi	a0,a0,-1798 # 8001f068 <itable>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	3e4080e7          	jalr	996(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    8000377e:	0001c497          	auipc	s1,0x1c
    80003782:	91248493          	addi	s1,s1,-1774 # 8001f090 <itable+0x28>
    80003786:	0001d997          	auipc	s3,0x1d
    8000378a:	39a98993          	addi	s3,s3,922 # 80020b20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000378e:	00005917          	auipc	s2,0x5
    80003792:	e3290913          	addi	s2,s2,-462 # 800085c0 <syscalls+0x170>
    80003796:	85ca                	mv	a1,s2
    80003798:	8526                	mv	a0,s1
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	e3a080e7          	jalr	-454(ra) # 800045d4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037a2:	08848493          	addi	s1,s1,136
    800037a6:	ff3498e3          	bne	s1,s3,80003796 <iinit+0x3e>
}
    800037aa:	70a2                	ld	ra,40(sp)
    800037ac:	7402                	ld	s0,32(sp)
    800037ae:	64e2                	ld	s1,24(sp)
    800037b0:	6942                	ld	s2,16(sp)
    800037b2:	69a2                	ld	s3,8(sp)
    800037b4:	6145                	addi	sp,sp,48
    800037b6:	8082                	ret

00000000800037b8 <ialloc>:
{
    800037b8:	715d                	addi	sp,sp,-80
    800037ba:	e486                	sd	ra,72(sp)
    800037bc:	e0a2                	sd	s0,64(sp)
    800037be:	fc26                	sd	s1,56(sp)
    800037c0:	f84a                	sd	s2,48(sp)
    800037c2:	f44e                	sd	s3,40(sp)
    800037c4:	f052                	sd	s4,32(sp)
    800037c6:	ec56                	sd	s5,24(sp)
    800037c8:	e85a                	sd	s6,16(sp)
    800037ca:	e45e                	sd	s7,8(sp)
    800037cc:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ce:	0001c717          	auipc	a4,0x1c
    800037d2:	88672703          	lw	a4,-1914(a4) # 8001f054 <sb+0xc>
    800037d6:	4785                	li	a5,1
    800037d8:	04e7fa63          	bgeu	a5,a4,8000382c <ialloc+0x74>
    800037dc:	8aaa                	mv	s5,a0
    800037de:	8bae                	mv	s7,a1
    800037e0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037e2:	0001ca17          	auipc	s4,0x1c
    800037e6:	866a0a13          	addi	s4,s4,-1946 # 8001f048 <sb>
    800037ea:	00048b1b          	sext.w	s6,s1
    800037ee:	0044d593          	srli	a1,s1,0x4
    800037f2:	018a2783          	lw	a5,24(s4)
    800037f6:	9dbd                	addw	a1,a1,a5
    800037f8:	8556                	mv	a0,s5
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	940080e7          	jalr	-1728(ra) # 8000313a <bread>
    80003802:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003804:	05850993          	addi	s3,a0,88
    80003808:	00f4f793          	andi	a5,s1,15
    8000380c:	079a                	slli	a5,a5,0x6
    8000380e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003810:	00099783          	lh	a5,0(s3)
    80003814:	c3a1                	beqz	a5,80003854 <ialloc+0x9c>
    brelse(bp);
    80003816:	00000097          	auipc	ra,0x0
    8000381a:	a54080e7          	jalr	-1452(ra) # 8000326a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000381e:	0485                	addi	s1,s1,1
    80003820:	00ca2703          	lw	a4,12(s4)
    80003824:	0004879b          	sext.w	a5,s1
    80003828:	fce7e1e3          	bltu	a5,a4,800037ea <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000382c:	00005517          	auipc	a0,0x5
    80003830:	d9c50513          	addi	a0,a0,-612 # 800085c8 <syscalls+0x178>
    80003834:	ffffd097          	auipc	ra,0xffffd
    80003838:	d5a080e7          	jalr	-678(ra) # 8000058e <printf>
  return 0;
    8000383c:	4501                	li	a0,0
}
    8000383e:	60a6                	ld	ra,72(sp)
    80003840:	6406                	ld	s0,64(sp)
    80003842:	74e2                	ld	s1,56(sp)
    80003844:	7942                	ld	s2,48(sp)
    80003846:	79a2                	ld	s3,40(sp)
    80003848:	7a02                	ld	s4,32(sp)
    8000384a:	6ae2                	ld	s5,24(sp)
    8000384c:	6b42                	ld	s6,16(sp)
    8000384e:	6ba2                	ld	s7,8(sp)
    80003850:	6161                	addi	sp,sp,80
    80003852:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003854:	04000613          	li	a2,64
    80003858:	4581                	li	a1,0
    8000385a:	854e                	mv	a0,s3
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	48a080e7          	jalr	1162(ra) # 80000ce6 <memset>
      dip->type = type;
    80003864:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003868:	854a                	mv	a0,s2
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	c84080e7          	jalr	-892(ra) # 800044ee <log_write>
      brelse(bp);
    80003872:	854a                	mv	a0,s2
    80003874:	00000097          	auipc	ra,0x0
    80003878:	9f6080e7          	jalr	-1546(ra) # 8000326a <brelse>
      return iget(dev, inum);
    8000387c:	85da                	mv	a1,s6
    8000387e:	8556                	mv	a0,s5
    80003880:	00000097          	auipc	ra,0x0
    80003884:	d9c080e7          	jalr	-612(ra) # 8000361c <iget>
    80003888:	bf5d                	j	8000383e <ialloc+0x86>

000000008000388a <iupdate>:
{
    8000388a:	1101                	addi	sp,sp,-32
    8000388c:	ec06                	sd	ra,24(sp)
    8000388e:	e822                	sd	s0,16(sp)
    80003890:	e426                	sd	s1,8(sp)
    80003892:	e04a                	sd	s2,0(sp)
    80003894:	1000                	addi	s0,sp,32
    80003896:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003898:	415c                	lw	a5,4(a0)
    8000389a:	0047d79b          	srliw	a5,a5,0x4
    8000389e:	0001b597          	auipc	a1,0x1b
    800038a2:	7c25a583          	lw	a1,1986(a1) # 8001f060 <sb+0x18>
    800038a6:	9dbd                	addw	a1,a1,a5
    800038a8:	4108                	lw	a0,0(a0)
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	890080e7          	jalr	-1904(ra) # 8000313a <bread>
    800038b2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038b4:	05850793          	addi	a5,a0,88
    800038b8:	40c8                	lw	a0,4(s1)
    800038ba:	893d                	andi	a0,a0,15
    800038bc:	051a                	slli	a0,a0,0x6
    800038be:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038c0:	04449703          	lh	a4,68(s1)
    800038c4:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038c8:	04649703          	lh	a4,70(s1)
    800038cc:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038d0:	04849703          	lh	a4,72(s1)
    800038d4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038d8:	04a49703          	lh	a4,74(s1)
    800038dc:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038e0:	44f8                	lw	a4,76(s1)
    800038e2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038e4:	03400613          	li	a2,52
    800038e8:	05048593          	addi	a1,s1,80
    800038ec:	0531                	addi	a0,a0,12
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	458080e7          	jalr	1112(ra) # 80000d46 <memmove>
  log_write(bp);
    800038f6:	854a                	mv	a0,s2
    800038f8:	00001097          	auipc	ra,0x1
    800038fc:	bf6080e7          	jalr	-1034(ra) # 800044ee <log_write>
  brelse(bp);
    80003900:	854a                	mv	a0,s2
    80003902:	00000097          	auipc	ra,0x0
    80003906:	968080e7          	jalr	-1688(ra) # 8000326a <brelse>
}
    8000390a:	60e2                	ld	ra,24(sp)
    8000390c:	6442                	ld	s0,16(sp)
    8000390e:	64a2                	ld	s1,8(sp)
    80003910:	6902                	ld	s2,0(sp)
    80003912:	6105                	addi	sp,sp,32
    80003914:	8082                	ret

0000000080003916 <idup>:
{
    80003916:	1101                	addi	sp,sp,-32
    80003918:	ec06                	sd	ra,24(sp)
    8000391a:	e822                	sd	s0,16(sp)
    8000391c:	e426                	sd	s1,8(sp)
    8000391e:	1000                	addi	s0,sp,32
    80003920:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003922:	0001b517          	auipc	a0,0x1b
    80003926:	74650513          	addi	a0,a0,1862 # 8001f068 <itable>
    8000392a:	ffffd097          	auipc	ra,0xffffd
    8000392e:	2c0080e7          	jalr	704(ra) # 80000bea <acquire>
  ip->ref++;
    80003932:	449c                	lw	a5,8(s1)
    80003934:	2785                	addiw	a5,a5,1
    80003936:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003938:	0001b517          	auipc	a0,0x1b
    8000393c:	73050513          	addi	a0,a0,1840 # 8001f068 <itable>
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	35e080e7          	jalr	862(ra) # 80000c9e <release>
}
    80003948:	8526                	mv	a0,s1
    8000394a:	60e2                	ld	ra,24(sp)
    8000394c:	6442                	ld	s0,16(sp)
    8000394e:	64a2                	ld	s1,8(sp)
    80003950:	6105                	addi	sp,sp,32
    80003952:	8082                	ret

0000000080003954 <ilock>:
{
    80003954:	1101                	addi	sp,sp,-32
    80003956:	ec06                	sd	ra,24(sp)
    80003958:	e822                	sd	s0,16(sp)
    8000395a:	e426                	sd	s1,8(sp)
    8000395c:	e04a                	sd	s2,0(sp)
    8000395e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003960:	c115                	beqz	a0,80003984 <ilock+0x30>
    80003962:	84aa                	mv	s1,a0
    80003964:	451c                	lw	a5,8(a0)
    80003966:	00f05f63          	blez	a5,80003984 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000396a:	0541                	addi	a0,a0,16
    8000396c:	00001097          	auipc	ra,0x1
    80003970:	ca2080e7          	jalr	-862(ra) # 8000460e <acquiresleep>
  if(ip->valid == 0){
    80003974:	40bc                	lw	a5,64(s1)
    80003976:	cf99                	beqz	a5,80003994 <ilock+0x40>
}
    80003978:	60e2                	ld	ra,24(sp)
    8000397a:	6442                	ld	s0,16(sp)
    8000397c:	64a2                	ld	s1,8(sp)
    8000397e:	6902                	ld	s2,0(sp)
    80003980:	6105                	addi	sp,sp,32
    80003982:	8082                	ret
    panic("ilock");
    80003984:	00005517          	auipc	a0,0x5
    80003988:	c5c50513          	addi	a0,a0,-932 # 800085e0 <syscalls+0x190>
    8000398c:	ffffd097          	auipc	ra,0xffffd
    80003990:	bb8080e7          	jalr	-1096(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003994:	40dc                	lw	a5,4(s1)
    80003996:	0047d79b          	srliw	a5,a5,0x4
    8000399a:	0001b597          	auipc	a1,0x1b
    8000399e:	6c65a583          	lw	a1,1734(a1) # 8001f060 <sb+0x18>
    800039a2:	9dbd                	addw	a1,a1,a5
    800039a4:	4088                	lw	a0,0(s1)
    800039a6:	fffff097          	auipc	ra,0xfffff
    800039aa:	794080e7          	jalr	1940(ra) # 8000313a <bread>
    800039ae:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039b0:	05850593          	addi	a1,a0,88
    800039b4:	40dc                	lw	a5,4(s1)
    800039b6:	8bbd                	andi	a5,a5,15
    800039b8:	079a                	slli	a5,a5,0x6
    800039ba:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039bc:	00059783          	lh	a5,0(a1)
    800039c0:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039c4:	00259783          	lh	a5,2(a1)
    800039c8:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039cc:	00459783          	lh	a5,4(a1)
    800039d0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039d4:	00659783          	lh	a5,6(a1)
    800039d8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039dc:	459c                	lw	a5,8(a1)
    800039de:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039e0:	03400613          	li	a2,52
    800039e4:	05b1                	addi	a1,a1,12
    800039e6:	05048513          	addi	a0,s1,80
    800039ea:	ffffd097          	auipc	ra,0xffffd
    800039ee:	35c080e7          	jalr	860(ra) # 80000d46 <memmove>
    brelse(bp);
    800039f2:	854a                	mv	a0,s2
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	876080e7          	jalr	-1930(ra) # 8000326a <brelse>
    ip->valid = 1;
    800039fc:	4785                	li	a5,1
    800039fe:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a00:	04449783          	lh	a5,68(s1)
    80003a04:	fbb5                	bnez	a5,80003978 <ilock+0x24>
      panic("ilock: no type");
    80003a06:	00005517          	auipc	a0,0x5
    80003a0a:	be250513          	addi	a0,a0,-1054 # 800085e8 <syscalls+0x198>
    80003a0e:	ffffd097          	auipc	ra,0xffffd
    80003a12:	b36080e7          	jalr	-1226(ra) # 80000544 <panic>

0000000080003a16 <iunlock>:
{
    80003a16:	1101                	addi	sp,sp,-32
    80003a18:	ec06                	sd	ra,24(sp)
    80003a1a:	e822                	sd	s0,16(sp)
    80003a1c:	e426                	sd	s1,8(sp)
    80003a1e:	e04a                	sd	s2,0(sp)
    80003a20:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a22:	c905                	beqz	a0,80003a52 <iunlock+0x3c>
    80003a24:	84aa                	mv	s1,a0
    80003a26:	01050913          	addi	s2,a0,16
    80003a2a:	854a                	mv	a0,s2
    80003a2c:	00001097          	auipc	ra,0x1
    80003a30:	c7c080e7          	jalr	-900(ra) # 800046a8 <holdingsleep>
    80003a34:	cd19                	beqz	a0,80003a52 <iunlock+0x3c>
    80003a36:	449c                	lw	a5,8(s1)
    80003a38:	00f05d63          	blez	a5,80003a52 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a3c:	854a                	mv	a0,s2
    80003a3e:	00001097          	auipc	ra,0x1
    80003a42:	c26080e7          	jalr	-986(ra) # 80004664 <releasesleep>
}
    80003a46:	60e2                	ld	ra,24(sp)
    80003a48:	6442                	ld	s0,16(sp)
    80003a4a:	64a2                	ld	s1,8(sp)
    80003a4c:	6902                	ld	s2,0(sp)
    80003a4e:	6105                	addi	sp,sp,32
    80003a50:	8082                	ret
    panic("iunlock");
    80003a52:	00005517          	auipc	a0,0x5
    80003a56:	ba650513          	addi	a0,a0,-1114 # 800085f8 <syscalls+0x1a8>
    80003a5a:	ffffd097          	auipc	ra,0xffffd
    80003a5e:	aea080e7          	jalr	-1302(ra) # 80000544 <panic>

0000000080003a62 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a62:	7179                	addi	sp,sp,-48
    80003a64:	f406                	sd	ra,40(sp)
    80003a66:	f022                	sd	s0,32(sp)
    80003a68:	ec26                	sd	s1,24(sp)
    80003a6a:	e84a                	sd	s2,16(sp)
    80003a6c:	e44e                	sd	s3,8(sp)
    80003a6e:	e052                	sd	s4,0(sp)
    80003a70:	1800                	addi	s0,sp,48
    80003a72:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a74:	05050493          	addi	s1,a0,80
    80003a78:	08050913          	addi	s2,a0,128
    80003a7c:	a021                	j	80003a84 <itrunc+0x22>
    80003a7e:	0491                	addi	s1,s1,4
    80003a80:	01248d63          	beq	s1,s2,80003a9a <itrunc+0x38>
    if(ip->addrs[i]){
    80003a84:	408c                	lw	a1,0(s1)
    80003a86:	dde5                	beqz	a1,80003a7e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a88:	0009a503          	lw	a0,0(s3)
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	8f4080e7          	jalr	-1804(ra) # 80003380 <bfree>
      ip->addrs[i] = 0;
    80003a94:	0004a023          	sw	zero,0(s1)
    80003a98:	b7dd                	j	80003a7e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a9a:	0809a583          	lw	a1,128(s3)
    80003a9e:	e185                	bnez	a1,80003abe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003aa0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aa4:	854e                	mv	a0,s3
    80003aa6:	00000097          	auipc	ra,0x0
    80003aaa:	de4080e7          	jalr	-540(ra) # 8000388a <iupdate>
}
    80003aae:	70a2                	ld	ra,40(sp)
    80003ab0:	7402                	ld	s0,32(sp)
    80003ab2:	64e2                	ld	s1,24(sp)
    80003ab4:	6942                	ld	s2,16(sp)
    80003ab6:	69a2                	ld	s3,8(sp)
    80003ab8:	6a02                	ld	s4,0(sp)
    80003aba:	6145                	addi	sp,sp,48
    80003abc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003abe:	0009a503          	lw	a0,0(s3)
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	678080e7          	jalr	1656(ra) # 8000313a <bread>
    80003aca:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003acc:	05850493          	addi	s1,a0,88
    80003ad0:	45850913          	addi	s2,a0,1112
    80003ad4:	a811                	j	80003ae8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003ad6:	0009a503          	lw	a0,0(s3)
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	8a6080e7          	jalr	-1882(ra) # 80003380 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ae2:	0491                	addi	s1,s1,4
    80003ae4:	01248563          	beq	s1,s2,80003aee <itrunc+0x8c>
      if(a[j])
    80003ae8:	408c                	lw	a1,0(s1)
    80003aea:	dde5                	beqz	a1,80003ae2 <itrunc+0x80>
    80003aec:	b7ed                	j	80003ad6 <itrunc+0x74>
    brelse(bp);
    80003aee:	8552                	mv	a0,s4
    80003af0:	fffff097          	auipc	ra,0xfffff
    80003af4:	77a080e7          	jalr	1914(ra) # 8000326a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003af8:	0809a583          	lw	a1,128(s3)
    80003afc:	0009a503          	lw	a0,0(s3)
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	880080e7          	jalr	-1920(ra) # 80003380 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b08:	0809a023          	sw	zero,128(s3)
    80003b0c:	bf51                	j	80003aa0 <itrunc+0x3e>

0000000080003b0e <iput>:
{
    80003b0e:	1101                	addi	sp,sp,-32
    80003b10:	ec06                	sd	ra,24(sp)
    80003b12:	e822                	sd	s0,16(sp)
    80003b14:	e426                	sd	s1,8(sp)
    80003b16:	e04a                	sd	s2,0(sp)
    80003b18:	1000                	addi	s0,sp,32
    80003b1a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b1c:	0001b517          	auipc	a0,0x1b
    80003b20:	54c50513          	addi	a0,a0,1356 # 8001f068 <itable>
    80003b24:	ffffd097          	auipc	ra,0xffffd
    80003b28:	0c6080e7          	jalr	198(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b2c:	4498                	lw	a4,8(s1)
    80003b2e:	4785                	li	a5,1
    80003b30:	02f70363          	beq	a4,a5,80003b56 <iput+0x48>
  ip->ref--;
    80003b34:	449c                	lw	a5,8(s1)
    80003b36:	37fd                	addiw	a5,a5,-1
    80003b38:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b3a:	0001b517          	auipc	a0,0x1b
    80003b3e:	52e50513          	addi	a0,a0,1326 # 8001f068 <itable>
    80003b42:	ffffd097          	auipc	ra,0xffffd
    80003b46:	15c080e7          	jalr	348(ra) # 80000c9e <release>
}
    80003b4a:	60e2                	ld	ra,24(sp)
    80003b4c:	6442                	ld	s0,16(sp)
    80003b4e:	64a2                	ld	s1,8(sp)
    80003b50:	6902                	ld	s2,0(sp)
    80003b52:	6105                	addi	sp,sp,32
    80003b54:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b56:	40bc                	lw	a5,64(s1)
    80003b58:	dff1                	beqz	a5,80003b34 <iput+0x26>
    80003b5a:	04a49783          	lh	a5,74(s1)
    80003b5e:	fbf9                	bnez	a5,80003b34 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b60:	01048913          	addi	s2,s1,16
    80003b64:	854a                	mv	a0,s2
    80003b66:	00001097          	auipc	ra,0x1
    80003b6a:	aa8080e7          	jalr	-1368(ra) # 8000460e <acquiresleep>
    release(&itable.lock);
    80003b6e:	0001b517          	auipc	a0,0x1b
    80003b72:	4fa50513          	addi	a0,a0,1274 # 8001f068 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	128080e7          	jalr	296(ra) # 80000c9e <release>
    itrunc(ip);
    80003b7e:	8526                	mv	a0,s1
    80003b80:	00000097          	auipc	ra,0x0
    80003b84:	ee2080e7          	jalr	-286(ra) # 80003a62 <itrunc>
    ip->type = 0;
    80003b88:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	00000097          	auipc	ra,0x0
    80003b92:	cfc080e7          	jalr	-772(ra) # 8000388a <iupdate>
    ip->valid = 0;
    80003b96:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b9a:	854a                	mv	a0,s2
    80003b9c:	00001097          	auipc	ra,0x1
    80003ba0:	ac8080e7          	jalr	-1336(ra) # 80004664 <releasesleep>
    acquire(&itable.lock);
    80003ba4:	0001b517          	auipc	a0,0x1b
    80003ba8:	4c450513          	addi	a0,a0,1220 # 8001f068 <itable>
    80003bac:	ffffd097          	auipc	ra,0xffffd
    80003bb0:	03e080e7          	jalr	62(ra) # 80000bea <acquire>
    80003bb4:	b741                	j	80003b34 <iput+0x26>

0000000080003bb6 <iunlockput>:
{
    80003bb6:	1101                	addi	sp,sp,-32
    80003bb8:	ec06                	sd	ra,24(sp)
    80003bba:	e822                	sd	s0,16(sp)
    80003bbc:	e426                	sd	s1,8(sp)
    80003bbe:	1000                	addi	s0,sp,32
    80003bc0:	84aa                	mv	s1,a0
  iunlock(ip);
    80003bc2:	00000097          	auipc	ra,0x0
    80003bc6:	e54080e7          	jalr	-428(ra) # 80003a16 <iunlock>
  iput(ip);
    80003bca:	8526                	mv	a0,s1
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	f42080e7          	jalr	-190(ra) # 80003b0e <iput>
}
    80003bd4:	60e2                	ld	ra,24(sp)
    80003bd6:	6442                	ld	s0,16(sp)
    80003bd8:	64a2                	ld	s1,8(sp)
    80003bda:	6105                	addi	sp,sp,32
    80003bdc:	8082                	ret

0000000080003bde <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bde:	1141                	addi	sp,sp,-16
    80003be0:	e422                	sd	s0,8(sp)
    80003be2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003be4:	411c                	lw	a5,0(a0)
    80003be6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003be8:	415c                	lw	a5,4(a0)
    80003bea:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bec:	04451783          	lh	a5,68(a0)
    80003bf0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bf4:	04a51783          	lh	a5,74(a0)
    80003bf8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bfc:	04c56783          	lwu	a5,76(a0)
    80003c00:	e99c                	sd	a5,16(a1)
}
    80003c02:	6422                	ld	s0,8(sp)
    80003c04:	0141                	addi	sp,sp,16
    80003c06:	8082                	ret

0000000080003c08 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c08:	457c                	lw	a5,76(a0)
    80003c0a:	0ed7e963          	bltu	a5,a3,80003cfc <readi+0xf4>
{
    80003c0e:	7159                	addi	sp,sp,-112
    80003c10:	f486                	sd	ra,104(sp)
    80003c12:	f0a2                	sd	s0,96(sp)
    80003c14:	eca6                	sd	s1,88(sp)
    80003c16:	e8ca                	sd	s2,80(sp)
    80003c18:	e4ce                	sd	s3,72(sp)
    80003c1a:	e0d2                	sd	s4,64(sp)
    80003c1c:	fc56                	sd	s5,56(sp)
    80003c1e:	f85a                	sd	s6,48(sp)
    80003c20:	f45e                	sd	s7,40(sp)
    80003c22:	f062                	sd	s8,32(sp)
    80003c24:	ec66                	sd	s9,24(sp)
    80003c26:	e86a                	sd	s10,16(sp)
    80003c28:	e46e                	sd	s11,8(sp)
    80003c2a:	1880                	addi	s0,sp,112
    80003c2c:	8b2a                	mv	s6,a0
    80003c2e:	8bae                	mv	s7,a1
    80003c30:	8a32                	mv	s4,a2
    80003c32:	84b6                	mv	s1,a3
    80003c34:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c36:	9f35                	addw	a4,a4,a3
    return 0;
    80003c38:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c3a:	0ad76063          	bltu	a4,a3,80003cda <readi+0xd2>
  if(off + n > ip->size)
    80003c3e:	00e7f463          	bgeu	a5,a4,80003c46 <readi+0x3e>
    n = ip->size - off;
    80003c42:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c46:	0a0a8963          	beqz	s5,80003cf8 <readi+0xf0>
    80003c4a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c4c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c50:	5c7d                	li	s8,-1
    80003c52:	a82d                	j	80003c8c <readi+0x84>
    80003c54:	020d1d93          	slli	s11,s10,0x20
    80003c58:	020ddd93          	srli	s11,s11,0x20
    80003c5c:	05890613          	addi	a2,s2,88
    80003c60:	86ee                	mv	a3,s11
    80003c62:	963a                	add	a2,a2,a4
    80003c64:	85d2                	mv	a1,s4
    80003c66:	855e                	mv	a0,s7
    80003c68:	fffff097          	auipc	ra,0xfffff
    80003c6c:	a16080e7          	jalr	-1514(ra) # 8000267e <either_copyout>
    80003c70:	05850d63          	beq	a0,s8,80003cca <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c74:	854a                	mv	a0,s2
    80003c76:	fffff097          	auipc	ra,0xfffff
    80003c7a:	5f4080e7          	jalr	1524(ra) # 8000326a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c7e:	013d09bb          	addw	s3,s10,s3
    80003c82:	009d04bb          	addw	s1,s10,s1
    80003c86:	9a6e                	add	s4,s4,s11
    80003c88:	0559f763          	bgeu	s3,s5,80003cd6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c8c:	00a4d59b          	srliw	a1,s1,0xa
    80003c90:	855a                	mv	a0,s6
    80003c92:	00000097          	auipc	ra,0x0
    80003c96:	8a2080e7          	jalr	-1886(ra) # 80003534 <bmap>
    80003c9a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c9e:	cd85                	beqz	a1,80003cd6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ca0:	000b2503          	lw	a0,0(s6)
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	496080e7          	jalr	1174(ra) # 8000313a <bread>
    80003cac:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cae:	3ff4f713          	andi	a4,s1,1023
    80003cb2:	40ec87bb          	subw	a5,s9,a4
    80003cb6:	413a86bb          	subw	a3,s5,s3
    80003cba:	8d3e                	mv	s10,a5
    80003cbc:	2781                	sext.w	a5,a5
    80003cbe:	0006861b          	sext.w	a2,a3
    80003cc2:	f8f679e3          	bgeu	a2,a5,80003c54 <readi+0x4c>
    80003cc6:	8d36                	mv	s10,a3
    80003cc8:	b771                	j	80003c54 <readi+0x4c>
      brelse(bp);
    80003cca:	854a                	mv	a0,s2
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	59e080e7          	jalr	1438(ra) # 8000326a <brelse>
      tot = -1;
    80003cd4:	59fd                	li	s3,-1
  }
  return tot;
    80003cd6:	0009851b          	sext.w	a0,s3
}
    80003cda:	70a6                	ld	ra,104(sp)
    80003cdc:	7406                	ld	s0,96(sp)
    80003cde:	64e6                	ld	s1,88(sp)
    80003ce0:	6946                	ld	s2,80(sp)
    80003ce2:	69a6                	ld	s3,72(sp)
    80003ce4:	6a06                	ld	s4,64(sp)
    80003ce6:	7ae2                	ld	s5,56(sp)
    80003ce8:	7b42                	ld	s6,48(sp)
    80003cea:	7ba2                	ld	s7,40(sp)
    80003cec:	7c02                	ld	s8,32(sp)
    80003cee:	6ce2                	ld	s9,24(sp)
    80003cf0:	6d42                	ld	s10,16(sp)
    80003cf2:	6da2                	ld	s11,8(sp)
    80003cf4:	6165                	addi	sp,sp,112
    80003cf6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cf8:	89d6                	mv	s3,s5
    80003cfa:	bff1                	j	80003cd6 <readi+0xce>
    return 0;
    80003cfc:	4501                	li	a0,0
}
    80003cfe:	8082                	ret

0000000080003d00 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d00:	457c                	lw	a5,76(a0)
    80003d02:	10d7e863          	bltu	a5,a3,80003e12 <writei+0x112>
{
    80003d06:	7159                	addi	sp,sp,-112
    80003d08:	f486                	sd	ra,104(sp)
    80003d0a:	f0a2                	sd	s0,96(sp)
    80003d0c:	eca6                	sd	s1,88(sp)
    80003d0e:	e8ca                	sd	s2,80(sp)
    80003d10:	e4ce                	sd	s3,72(sp)
    80003d12:	e0d2                	sd	s4,64(sp)
    80003d14:	fc56                	sd	s5,56(sp)
    80003d16:	f85a                	sd	s6,48(sp)
    80003d18:	f45e                	sd	s7,40(sp)
    80003d1a:	f062                	sd	s8,32(sp)
    80003d1c:	ec66                	sd	s9,24(sp)
    80003d1e:	e86a                	sd	s10,16(sp)
    80003d20:	e46e                	sd	s11,8(sp)
    80003d22:	1880                	addi	s0,sp,112
    80003d24:	8aaa                	mv	s5,a0
    80003d26:	8bae                	mv	s7,a1
    80003d28:	8a32                	mv	s4,a2
    80003d2a:	8936                	mv	s2,a3
    80003d2c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d2e:	00e687bb          	addw	a5,a3,a4
    80003d32:	0ed7e263          	bltu	a5,a3,80003e16 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d36:	00043737          	lui	a4,0x43
    80003d3a:	0ef76063          	bltu	a4,a5,80003e1a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d3e:	0c0b0863          	beqz	s6,80003e0e <writei+0x10e>
    80003d42:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d44:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d48:	5c7d                	li	s8,-1
    80003d4a:	a091                	j	80003d8e <writei+0x8e>
    80003d4c:	020d1d93          	slli	s11,s10,0x20
    80003d50:	020ddd93          	srli	s11,s11,0x20
    80003d54:	05848513          	addi	a0,s1,88
    80003d58:	86ee                	mv	a3,s11
    80003d5a:	8652                	mv	a2,s4
    80003d5c:	85de                	mv	a1,s7
    80003d5e:	953a                	add	a0,a0,a4
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	974080e7          	jalr	-1676(ra) # 800026d4 <either_copyin>
    80003d68:	07850263          	beq	a0,s8,80003dcc <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d6c:	8526                	mv	a0,s1
    80003d6e:	00000097          	auipc	ra,0x0
    80003d72:	780080e7          	jalr	1920(ra) # 800044ee <log_write>
    brelse(bp);
    80003d76:	8526                	mv	a0,s1
    80003d78:	fffff097          	auipc	ra,0xfffff
    80003d7c:	4f2080e7          	jalr	1266(ra) # 8000326a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d80:	013d09bb          	addw	s3,s10,s3
    80003d84:	012d093b          	addw	s2,s10,s2
    80003d88:	9a6e                	add	s4,s4,s11
    80003d8a:	0569f663          	bgeu	s3,s6,80003dd6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d8e:	00a9559b          	srliw	a1,s2,0xa
    80003d92:	8556                	mv	a0,s5
    80003d94:	fffff097          	auipc	ra,0xfffff
    80003d98:	7a0080e7          	jalr	1952(ra) # 80003534 <bmap>
    80003d9c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003da0:	c99d                	beqz	a1,80003dd6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003da2:	000aa503          	lw	a0,0(s5)
    80003da6:	fffff097          	auipc	ra,0xfffff
    80003daa:	394080e7          	jalr	916(ra) # 8000313a <bread>
    80003dae:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db0:	3ff97713          	andi	a4,s2,1023
    80003db4:	40ec87bb          	subw	a5,s9,a4
    80003db8:	413b06bb          	subw	a3,s6,s3
    80003dbc:	8d3e                	mv	s10,a5
    80003dbe:	2781                	sext.w	a5,a5
    80003dc0:	0006861b          	sext.w	a2,a3
    80003dc4:	f8f674e3          	bgeu	a2,a5,80003d4c <writei+0x4c>
    80003dc8:	8d36                	mv	s10,a3
    80003dca:	b749                	j	80003d4c <writei+0x4c>
      brelse(bp);
    80003dcc:	8526                	mv	a0,s1
    80003dce:	fffff097          	auipc	ra,0xfffff
    80003dd2:	49c080e7          	jalr	1180(ra) # 8000326a <brelse>
  }

  if(off > ip->size)
    80003dd6:	04caa783          	lw	a5,76(s5)
    80003dda:	0127f463          	bgeu	a5,s2,80003de2 <writei+0xe2>
    ip->size = off;
    80003dde:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003de2:	8556                	mv	a0,s5
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	aa6080e7          	jalr	-1370(ra) # 8000388a <iupdate>

  return tot;
    80003dec:	0009851b          	sext.w	a0,s3
}
    80003df0:	70a6                	ld	ra,104(sp)
    80003df2:	7406                	ld	s0,96(sp)
    80003df4:	64e6                	ld	s1,88(sp)
    80003df6:	6946                	ld	s2,80(sp)
    80003df8:	69a6                	ld	s3,72(sp)
    80003dfa:	6a06                	ld	s4,64(sp)
    80003dfc:	7ae2                	ld	s5,56(sp)
    80003dfe:	7b42                	ld	s6,48(sp)
    80003e00:	7ba2                	ld	s7,40(sp)
    80003e02:	7c02                	ld	s8,32(sp)
    80003e04:	6ce2                	ld	s9,24(sp)
    80003e06:	6d42                	ld	s10,16(sp)
    80003e08:	6da2                	ld	s11,8(sp)
    80003e0a:	6165                	addi	sp,sp,112
    80003e0c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e0e:	89da                	mv	s3,s6
    80003e10:	bfc9                	j	80003de2 <writei+0xe2>
    return -1;
    80003e12:	557d                	li	a0,-1
}
    80003e14:	8082                	ret
    return -1;
    80003e16:	557d                	li	a0,-1
    80003e18:	bfe1                	j	80003df0 <writei+0xf0>
    return -1;
    80003e1a:	557d                	li	a0,-1
    80003e1c:	bfd1                	j	80003df0 <writei+0xf0>

0000000080003e1e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e1e:	1141                	addi	sp,sp,-16
    80003e20:	e406                	sd	ra,8(sp)
    80003e22:	e022                	sd	s0,0(sp)
    80003e24:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e26:	4639                	li	a2,14
    80003e28:	ffffd097          	auipc	ra,0xffffd
    80003e2c:	f96080e7          	jalr	-106(ra) # 80000dbe <strncmp>
}
    80003e30:	60a2                	ld	ra,8(sp)
    80003e32:	6402                	ld	s0,0(sp)
    80003e34:	0141                	addi	sp,sp,16
    80003e36:	8082                	ret

0000000080003e38 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e38:	7139                	addi	sp,sp,-64
    80003e3a:	fc06                	sd	ra,56(sp)
    80003e3c:	f822                	sd	s0,48(sp)
    80003e3e:	f426                	sd	s1,40(sp)
    80003e40:	f04a                	sd	s2,32(sp)
    80003e42:	ec4e                	sd	s3,24(sp)
    80003e44:	e852                	sd	s4,16(sp)
    80003e46:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e48:	04451703          	lh	a4,68(a0)
    80003e4c:	4785                	li	a5,1
    80003e4e:	00f71a63          	bne	a4,a5,80003e62 <dirlookup+0x2a>
    80003e52:	892a                	mv	s2,a0
    80003e54:	89ae                	mv	s3,a1
    80003e56:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e58:	457c                	lw	a5,76(a0)
    80003e5a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e5c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e5e:	e79d                	bnez	a5,80003e8c <dirlookup+0x54>
    80003e60:	a8a5                	j	80003ed8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e62:	00004517          	auipc	a0,0x4
    80003e66:	79e50513          	addi	a0,a0,1950 # 80008600 <syscalls+0x1b0>
    80003e6a:	ffffc097          	auipc	ra,0xffffc
    80003e6e:	6da080e7          	jalr	1754(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003e72:	00004517          	auipc	a0,0x4
    80003e76:	7a650513          	addi	a0,a0,1958 # 80008618 <syscalls+0x1c8>
    80003e7a:	ffffc097          	auipc	ra,0xffffc
    80003e7e:	6ca080e7          	jalr	1738(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e82:	24c1                	addiw	s1,s1,16
    80003e84:	04c92783          	lw	a5,76(s2)
    80003e88:	04f4f763          	bgeu	s1,a5,80003ed6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e8c:	4741                	li	a4,16
    80003e8e:	86a6                	mv	a3,s1
    80003e90:	fc040613          	addi	a2,s0,-64
    80003e94:	4581                	li	a1,0
    80003e96:	854a                	mv	a0,s2
    80003e98:	00000097          	auipc	ra,0x0
    80003e9c:	d70080e7          	jalr	-656(ra) # 80003c08 <readi>
    80003ea0:	47c1                	li	a5,16
    80003ea2:	fcf518e3          	bne	a0,a5,80003e72 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ea6:	fc045783          	lhu	a5,-64(s0)
    80003eaa:	dfe1                	beqz	a5,80003e82 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003eac:	fc240593          	addi	a1,s0,-62
    80003eb0:	854e                	mv	a0,s3
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	f6c080e7          	jalr	-148(ra) # 80003e1e <namecmp>
    80003eba:	f561                	bnez	a0,80003e82 <dirlookup+0x4a>
      if(poff)
    80003ebc:	000a0463          	beqz	s4,80003ec4 <dirlookup+0x8c>
        *poff = off;
    80003ec0:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ec4:	fc045583          	lhu	a1,-64(s0)
    80003ec8:	00092503          	lw	a0,0(s2)
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	750080e7          	jalr	1872(ra) # 8000361c <iget>
    80003ed4:	a011                	j	80003ed8 <dirlookup+0xa0>
  return 0;
    80003ed6:	4501                	li	a0,0
}
    80003ed8:	70e2                	ld	ra,56(sp)
    80003eda:	7442                	ld	s0,48(sp)
    80003edc:	74a2                	ld	s1,40(sp)
    80003ede:	7902                	ld	s2,32(sp)
    80003ee0:	69e2                	ld	s3,24(sp)
    80003ee2:	6a42                	ld	s4,16(sp)
    80003ee4:	6121                	addi	sp,sp,64
    80003ee6:	8082                	ret

0000000080003ee8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ee8:	711d                	addi	sp,sp,-96
    80003eea:	ec86                	sd	ra,88(sp)
    80003eec:	e8a2                	sd	s0,80(sp)
    80003eee:	e4a6                	sd	s1,72(sp)
    80003ef0:	e0ca                	sd	s2,64(sp)
    80003ef2:	fc4e                	sd	s3,56(sp)
    80003ef4:	f852                	sd	s4,48(sp)
    80003ef6:	f456                	sd	s5,40(sp)
    80003ef8:	f05a                	sd	s6,32(sp)
    80003efa:	ec5e                	sd	s7,24(sp)
    80003efc:	e862                	sd	s8,16(sp)
    80003efe:	e466                	sd	s9,8(sp)
    80003f00:	1080                	addi	s0,sp,96
    80003f02:	84aa                	mv	s1,a0
    80003f04:	8b2e                	mv	s6,a1
    80003f06:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f08:	00054703          	lbu	a4,0(a0)
    80003f0c:	02f00793          	li	a5,47
    80003f10:	02f70363          	beq	a4,a5,80003f36 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f14:	ffffe097          	auipc	ra,0xffffe
    80003f18:	ab2080e7          	jalr	-1358(ra) # 800019c6 <myproc>
    80003f1c:	15053503          	ld	a0,336(a0)
    80003f20:	00000097          	auipc	ra,0x0
    80003f24:	9f6080e7          	jalr	-1546(ra) # 80003916 <idup>
    80003f28:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f2a:	02f00913          	li	s2,47
  len = path - s;
    80003f2e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f30:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f32:	4c05                	li	s8,1
    80003f34:	a865                	j	80003fec <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f36:	4585                	li	a1,1
    80003f38:	4505                	li	a0,1
    80003f3a:	fffff097          	auipc	ra,0xfffff
    80003f3e:	6e2080e7          	jalr	1762(ra) # 8000361c <iget>
    80003f42:	89aa                	mv	s3,a0
    80003f44:	b7dd                	j	80003f2a <namex+0x42>
      iunlockput(ip);
    80003f46:	854e                	mv	a0,s3
    80003f48:	00000097          	auipc	ra,0x0
    80003f4c:	c6e080e7          	jalr	-914(ra) # 80003bb6 <iunlockput>
      return 0;
    80003f50:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f52:	854e                	mv	a0,s3
    80003f54:	60e6                	ld	ra,88(sp)
    80003f56:	6446                	ld	s0,80(sp)
    80003f58:	64a6                	ld	s1,72(sp)
    80003f5a:	6906                	ld	s2,64(sp)
    80003f5c:	79e2                	ld	s3,56(sp)
    80003f5e:	7a42                	ld	s4,48(sp)
    80003f60:	7aa2                	ld	s5,40(sp)
    80003f62:	7b02                	ld	s6,32(sp)
    80003f64:	6be2                	ld	s7,24(sp)
    80003f66:	6c42                	ld	s8,16(sp)
    80003f68:	6ca2                	ld	s9,8(sp)
    80003f6a:	6125                	addi	sp,sp,96
    80003f6c:	8082                	ret
      iunlock(ip);
    80003f6e:	854e                	mv	a0,s3
    80003f70:	00000097          	auipc	ra,0x0
    80003f74:	aa6080e7          	jalr	-1370(ra) # 80003a16 <iunlock>
      return ip;
    80003f78:	bfe9                	j	80003f52 <namex+0x6a>
      iunlockput(ip);
    80003f7a:	854e                	mv	a0,s3
    80003f7c:	00000097          	auipc	ra,0x0
    80003f80:	c3a080e7          	jalr	-966(ra) # 80003bb6 <iunlockput>
      return 0;
    80003f84:	89d2                	mv	s3,s4
    80003f86:	b7f1                	j	80003f52 <namex+0x6a>
  len = path - s;
    80003f88:	40b48633          	sub	a2,s1,a1
    80003f8c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f90:	094cd463          	bge	s9,s4,80004018 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f94:	4639                	li	a2,14
    80003f96:	8556                	mv	a0,s5
    80003f98:	ffffd097          	auipc	ra,0xffffd
    80003f9c:	dae080e7          	jalr	-594(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003fa0:	0004c783          	lbu	a5,0(s1)
    80003fa4:	01279763          	bne	a5,s2,80003fb2 <namex+0xca>
    path++;
    80003fa8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003faa:	0004c783          	lbu	a5,0(s1)
    80003fae:	ff278de3          	beq	a5,s2,80003fa8 <namex+0xc0>
    ilock(ip);
    80003fb2:	854e                	mv	a0,s3
    80003fb4:	00000097          	auipc	ra,0x0
    80003fb8:	9a0080e7          	jalr	-1632(ra) # 80003954 <ilock>
    if(ip->type != T_DIR){
    80003fbc:	04499783          	lh	a5,68(s3)
    80003fc0:	f98793e3          	bne	a5,s8,80003f46 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fc4:	000b0563          	beqz	s6,80003fce <namex+0xe6>
    80003fc8:	0004c783          	lbu	a5,0(s1)
    80003fcc:	d3cd                	beqz	a5,80003f6e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003fce:	865e                	mv	a2,s7
    80003fd0:	85d6                	mv	a1,s5
    80003fd2:	854e                	mv	a0,s3
    80003fd4:	00000097          	auipc	ra,0x0
    80003fd8:	e64080e7          	jalr	-412(ra) # 80003e38 <dirlookup>
    80003fdc:	8a2a                	mv	s4,a0
    80003fde:	dd51                	beqz	a0,80003f7a <namex+0x92>
    iunlockput(ip);
    80003fe0:	854e                	mv	a0,s3
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	bd4080e7          	jalr	-1068(ra) # 80003bb6 <iunlockput>
    ip = next;
    80003fea:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fec:	0004c783          	lbu	a5,0(s1)
    80003ff0:	05279763          	bne	a5,s2,8000403e <namex+0x156>
    path++;
    80003ff4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ff6:	0004c783          	lbu	a5,0(s1)
    80003ffa:	ff278de3          	beq	a5,s2,80003ff4 <namex+0x10c>
  if(*path == 0)
    80003ffe:	c79d                	beqz	a5,8000402c <namex+0x144>
    path++;
    80004000:	85a6                	mv	a1,s1
  len = path - s;
    80004002:	8a5e                	mv	s4,s7
    80004004:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004006:	01278963          	beq	a5,s2,80004018 <namex+0x130>
    8000400a:	dfbd                	beqz	a5,80003f88 <namex+0xa0>
    path++;
    8000400c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000400e:	0004c783          	lbu	a5,0(s1)
    80004012:	ff279ce3          	bne	a5,s2,8000400a <namex+0x122>
    80004016:	bf8d                	j	80003f88 <namex+0xa0>
    memmove(name, s, len);
    80004018:	2601                	sext.w	a2,a2
    8000401a:	8556                	mv	a0,s5
    8000401c:	ffffd097          	auipc	ra,0xffffd
    80004020:	d2a080e7          	jalr	-726(ra) # 80000d46 <memmove>
    name[len] = 0;
    80004024:	9a56                	add	s4,s4,s5
    80004026:	000a0023          	sb	zero,0(s4)
    8000402a:	bf9d                	j	80003fa0 <namex+0xb8>
  if(nameiparent){
    8000402c:	f20b03e3          	beqz	s6,80003f52 <namex+0x6a>
    iput(ip);
    80004030:	854e                	mv	a0,s3
    80004032:	00000097          	auipc	ra,0x0
    80004036:	adc080e7          	jalr	-1316(ra) # 80003b0e <iput>
    return 0;
    8000403a:	4981                	li	s3,0
    8000403c:	bf19                	j	80003f52 <namex+0x6a>
  if(*path == 0)
    8000403e:	d7fd                	beqz	a5,8000402c <namex+0x144>
  while(*path != '/' && *path != 0)
    80004040:	0004c783          	lbu	a5,0(s1)
    80004044:	85a6                	mv	a1,s1
    80004046:	b7d1                	j	8000400a <namex+0x122>

0000000080004048 <dirlink>:
{
    80004048:	7139                	addi	sp,sp,-64
    8000404a:	fc06                	sd	ra,56(sp)
    8000404c:	f822                	sd	s0,48(sp)
    8000404e:	f426                	sd	s1,40(sp)
    80004050:	f04a                	sd	s2,32(sp)
    80004052:	ec4e                	sd	s3,24(sp)
    80004054:	e852                	sd	s4,16(sp)
    80004056:	0080                	addi	s0,sp,64
    80004058:	892a                	mv	s2,a0
    8000405a:	8a2e                	mv	s4,a1
    8000405c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000405e:	4601                	li	a2,0
    80004060:	00000097          	auipc	ra,0x0
    80004064:	dd8080e7          	jalr	-552(ra) # 80003e38 <dirlookup>
    80004068:	e93d                	bnez	a0,800040de <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000406a:	04c92483          	lw	s1,76(s2)
    8000406e:	c49d                	beqz	s1,8000409c <dirlink+0x54>
    80004070:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004072:	4741                	li	a4,16
    80004074:	86a6                	mv	a3,s1
    80004076:	fc040613          	addi	a2,s0,-64
    8000407a:	4581                	li	a1,0
    8000407c:	854a                	mv	a0,s2
    8000407e:	00000097          	auipc	ra,0x0
    80004082:	b8a080e7          	jalr	-1142(ra) # 80003c08 <readi>
    80004086:	47c1                	li	a5,16
    80004088:	06f51163          	bne	a0,a5,800040ea <dirlink+0xa2>
    if(de.inum == 0)
    8000408c:	fc045783          	lhu	a5,-64(s0)
    80004090:	c791                	beqz	a5,8000409c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004092:	24c1                	addiw	s1,s1,16
    80004094:	04c92783          	lw	a5,76(s2)
    80004098:	fcf4ede3          	bltu	s1,a5,80004072 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000409c:	4639                	li	a2,14
    8000409e:	85d2                	mv	a1,s4
    800040a0:	fc240513          	addi	a0,s0,-62
    800040a4:	ffffd097          	auipc	ra,0xffffd
    800040a8:	d56080e7          	jalr	-682(ra) # 80000dfa <strncpy>
  de.inum = inum;
    800040ac:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040b0:	4741                	li	a4,16
    800040b2:	86a6                	mv	a3,s1
    800040b4:	fc040613          	addi	a2,s0,-64
    800040b8:	4581                	li	a1,0
    800040ba:	854a                	mv	a0,s2
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	c44080e7          	jalr	-956(ra) # 80003d00 <writei>
    800040c4:	1541                	addi	a0,a0,-16
    800040c6:	00a03533          	snez	a0,a0
    800040ca:	40a00533          	neg	a0,a0
}
    800040ce:	70e2                	ld	ra,56(sp)
    800040d0:	7442                	ld	s0,48(sp)
    800040d2:	74a2                	ld	s1,40(sp)
    800040d4:	7902                	ld	s2,32(sp)
    800040d6:	69e2                	ld	s3,24(sp)
    800040d8:	6a42                	ld	s4,16(sp)
    800040da:	6121                	addi	sp,sp,64
    800040dc:	8082                	ret
    iput(ip);
    800040de:	00000097          	auipc	ra,0x0
    800040e2:	a30080e7          	jalr	-1488(ra) # 80003b0e <iput>
    return -1;
    800040e6:	557d                	li	a0,-1
    800040e8:	b7dd                	j	800040ce <dirlink+0x86>
      panic("dirlink read");
    800040ea:	00004517          	auipc	a0,0x4
    800040ee:	53e50513          	addi	a0,a0,1342 # 80008628 <syscalls+0x1d8>
    800040f2:	ffffc097          	auipc	ra,0xffffc
    800040f6:	452080e7          	jalr	1106(ra) # 80000544 <panic>

00000000800040fa <namei>:

struct inode*
namei(char *path)
{
    800040fa:	1101                	addi	sp,sp,-32
    800040fc:	ec06                	sd	ra,24(sp)
    800040fe:	e822                	sd	s0,16(sp)
    80004100:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004102:	fe040613          	addi	a2,s0,-32
    80004106:	4581                	li	a1,0
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	de0080e7          	jalr	-544(ra) # 80003ee8 <namex>
}
    80004110:	60e2                	ld	ra,24(sp)
    80004112:	6442                	ld	s0,16(sp)
    80004114:	6105                	addi	sp,sp,32
    80004116:	8082                	ret

0000000080004118 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004118:	1141                	addi	sp,sp,-16
    8000411a:	e406                	sd	ra,8(sp)
    8000411c:	e022                	sd	s0,0(sp)
    8000411e:	0800                	addi	s0,sp,16
    80004120:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004122:	4585                	li	a1,1
    80004124:	00000097          	auipc	ra,0x0
    80004128:	dc4080e7          	jalr	-572(ra) # 80003ee8 <namex>
}
    8000412c:	60a2                	ld	ra,8(sp)
    8000412e:	6402                	ld	s0,0(sp)
    80004130:	0141                	addi	sp,sp,16
    80004132:	8082                	ret

0000000080004134 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004134:	1101                	addi	sp,sp,-32
    80004136:	ec06                	sd	ra,24(sp)
    80004138:	e822                	sd	s0,16(sp)
    8000413a:	e426                	sd	s1,8(sp)
    8000413c:	e04a                	sd	s2,0(sp)
    8000413e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004140:	0001d917          	auipc	s2,0x1d
    80004144:	9d090913          	addi	s2,s2,-1584 # 80020b10 <log>
    80004148:	01892583          	lw	a1,24(s2)
    8000414c:	02892503          	lw	a0,40(s2)
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	fea080e7          	jalr	-22(ra) # 8000313a <bread>
    80004158:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000415a:	02c92683          	lw	a3,44(s2)
    8000415e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004160:	02d05763          	blez	a3,8000418e <write_head+0x5a>
    80004164:	0001d797          	auipc	a5,0x1d
    80004168:	9dc78793          	addi	a5,a5,-1572 # 80020b40 <log+0x30>
    8000416c:	05c50713          	addi	a4,a0,92
    80004170:	36fd                	addiw	a3,a3,-1
    80004172:	1682                	slli	a3,a3,0x20
    80004174:	9281                	srli	a3,a3,0x20
    80004176:	068a                	slli	a3,a3,0x2
    80004178:	0001d617          	auipc	a2,0x1d
    8000417c:	9cc60613          	addi	a2,a2,-1588 # 80020b44 <log+0x34>
    80004180:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004182:	4390                	lw	a2,0(a5)
    80004184:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004186:	0791                	addi	a5,a5,4
    80004188:	0711                	addi	a4,a4,4
    8000418a:	fed79ce3          	bne	a5,a3,80004182 <write_head+0x4e>
  }
  bwrite(buf);
    8000418e:	8526                	mv	a0,s1
    80004190:	fffff097          	auipc	ra,0xfffff
    80004194:	09c080e7          	jalr	156(ra) # 8000322c <bwrite>
  brelse(buf);
    80004198:	8526                	mv	a0,s1
    8000419a:	fffff097          	auipc	ra,0xfffff
    8000419e:	0d0080e7          	jalr	208(ra) # 8000326a <brelse>
}
    800041a2:	60e2                	ld	ra,24(sp)
    800041a4:	6442                	ld	s0,16(sp)
    800041a6:	64a2                	ld	s1,8(sp)
    800041a8:	6902                	ld	s2,0(sp)
    800041aa:	6105                	addi	sp,sp,32
    800041ac:	8082                	ret

00000000800041ae <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041ae:	0001d797          	auipc	a5,0x1d
    800041b2:	98e7a783          	lw	a5,-1650(a5) # 80020b3c <log+0x2c>
    800041b6:	0af05d63          	blez	a5,80004270 <install_trans+0xc2>
{
    800041ba:	7139                	addi	sp,sp,-64
    800041bc:	fc06                	sd	ra,56(sp)
    800041be:	f822                	sd	s0,48(sp)
    800041c0:	f426                	sd	s1,40(sp)
    800041c2:	f04a                	sd	s2,32(sp)
    800041c4:	ec4e                	sd	s3,24(sp)
    800041c6:	e852                	sd	s4,16(sp)
    800041c8:	e456                	sd	s5,8(sp)
    800041ca:	e05a                	sd	s6,0(sp)
    800041cc:	0080                	addi	s0,sp,64
    800041ce:	8b2a                	mv	s6,a0
    800041d0:	0001da97          	auipc	s5,0x1d
    800041d4:	970a8a93          	addi	s5,s5,-1680 # 80020b40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041da:	0001d997          	auipc	s3,0x1d
    800041de:	93698993          	addi	s3,s3,-1738 # 80020b10 <log>
    800041e2:	a035                	j	8000420e <install_trans+0x60>
      bunpin(dbuf);
    800041e4:	8526                	mv	a0,s1
    800041e6:	fffff097          	auipc	ra,0xfffff
    800041ea:	15e080e7          	jalr	350(ra) # 80003344 <bunpin>
    brelse(lbuf);
    800041ee:	854a                	mv	a0,s2
    800041f0:	fffff097          	auipc	ra,0xfffff
    800041f4:	07a080e7          	jalr	122(ra) # 8000326a <brelse>
    brelse(dbuf);
    800041f8:	8526                	mv	a0,s1
    800041fa:	fffff097          	auipc	ra,0xfffff
    800041fe:	070080e7          	jalr	112(ra) # 8000326a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004202:	2a05                	addiw	s4,s4,1
    80004204:	0a91                	addi	s5,s5,4
    80004206:	02c9a783          	lw	a5,44(s3)
    8000420a:	04fa5963          	bge	s4,a5,8000425c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000420e:	0189a583          	lw	a1,24(s3)
    80004212:	014585bb          	addw	a1,a1,s4
    80004216:	2585                	addiw	a1,a1,1
    80004218:	0289a503          	lw	a0,40(s3)
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	f1e080e7          	jalr	-226(ra) # 8000313a <bread>
    80004224:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004226:	000aa583          	lw	a1,0(s5)
    8000422a:	0289a503          	lw	a0,40(s3)
    8000422e:	fffff097          	auipc	ra,0xfffff
    80004232:	f0c080e7          	jalr	-244(ra) # 8000313a <bread>
    80004236:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004238:	40000613          	li	a2,1024
    8000423c:	05890593          	addi	a1,s2,88
    80004240:	05850513          	addi	a0,a0,88
    80004244:	ffffd097          	auipc	ra,0xffffd
    80004248:	b02080e7          	jalr	-1278(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000424c:	8526                	mv	a0,s1
    8000424e:	fffff097          	auipc	ra,0xfffff
    80004252:	fde080e7          	jalr	-34(ra) # 8000322c <bwrite>
    if(recovering == 0)
    80004256:	f80b1ce3          	bnez	s6,800041ee <install_trans+0x40>
    8000425a:	b769                	j	800041e4 <install_trans+0x36>
}
    8000425c:	70e2                	ld	ra,56(sp)
    8000425e:	7442                	ld	s0,48(sp)
    80004260:	74a2                	ld	s1,40(sp)
    80004262:	7902                	ld	s2,32(sp)
    80004264:	69e2                	ld	s3,24(sp)
    80004266:	6a42                	ld	s4,16(sp)
    80004268:	6aa2                	ld	s5,8(sp)
    8000426a:	6b02                	ld	s6,0(sp)
    8000426c:	6121                	addi	sp,sp,64
    8000426e:	8082                	ret
    80004270:	8082                	ret

0000000080004272 <initlog>:
{
    80004272:	7179                	addi	sp,sp,-48
    80004274:	f406                	sd	ra,40(sp)
    80004276:	f022                	sd	s0,32(sp)
    80004278:	ec26                	sd	s1,24(sp)
    8000427a:	e84a                	sd	s2,16(sp)
    8000427c:	e44e                	sd	s3,8(sp)
    8000427e:	1800                	addi	s0,sp,48
    80004280:	892a                	mv	s2,a0
    80004282:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004284:	0001d497          	auipc	s1,0x1d
    80004288:	88c48493          	addi	s1,s1,-1908 # 80020b10 <log>
    8000428c:	00004597          	auipc	a1,0x4
    80004290:	3ac58593          	addi	a1,a1,940 # 80008638 <syscalls+0x1e8>
    80004294:	8526                	mv	a0,s1
    80004296:	ffffd097          	auipc	ra,0xffffd
    8000429a:	8c4080e7          	jalr	-1852(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000429e:	0149a583          	lw	a1,20(s3)
    800042a2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042a4:	0109a783          	lw	a5,16(s3)
    800042a8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042aa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042ae:	854a                	mv	a0,s2
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	e8a080e7          	jalr	-374(ra) # 8000313a <bread>
  log.lh.n = lh->n;
    800042b8:	4d3c                	lw	a5,88(a0)
    800042ba:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042bc:	02f05563          	blez	a5,800042e6 <initlog+0x74>
    800042c0:	05c50713          	addi	a4,a0,92
    800042c4:	0001d697          	auipc	a3,0x1d
    800042c8:	87c68693          	addi	a3,a3,-1924 # 80020b40 <log+0x30>
    800042cc:	37fd                	addiw	a5,a5,-1
    800042ce:	1782                	slli	a5,a5,0x20
    800042d0:	9381                	srli	a5,a5,0x20
    800042d2:	078a                	slli	a5,a5,0x2
    800042d4:	06050613          	addi	a2,a0,96
    800042d8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042da:	4310                	lw	a2,0(a4)
    800042dc:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042de:	0711                	addi	a4,a4,4
    800042e0:	0691                	addi	a3,a3,4
    800042e2:	fef71ce3          	bne	a4,a5,800042da <initlog+0x68>
  brelse(buf);
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	f84080e7          	jalr	-124(ra) # 8000326a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042ee:	4505                	li	a0,1
    800042f0:	00000097          	auipc	ra,0x0
    800042f4:	ebe080e7          	jalr	-322(ra) # 800041ae <install_trans>
  log.lh.n = 0;
    800042f8:	0001d797          	auipc	a5,0x1d
    800042fc:	8407a223          	sw	zero,-1980(a5) # 80020b3c <log+0x2c>
  write_head(); // clear the log
    80004300:	00000097          	auipc	ra,0x0
    80004304:	e34080e7          	jalr	-460(ra) # 80004134 <write_head>
}
    80004308:	70a2                	ld	ra,40(sp)
    8000430a:	7402                	ld	s0,32(sp)
    8000430c:	64e2                	ld	s1,24(sp)
    8000430e:	6942                	ld	s2,16(sp)
    80004310:	69a2                	ld	s3,8(sp)
    80004312:	6145                	addi	sp,sp,48
    80004314:	8082                	ret

0000000080004316 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004316:	1101                	addi	sp,sp,-32
    80004318:	ec06                	sd	ra,24(sp)
    8000431a:	e822                	sd	s0,16(sp)
    8000431c:	e426                	sd	s1,8(sp)
    8000431e:	e04a                	sd	s2,0(sp)
    80004320:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004322:	0001c517          	auipc	a0,0x1c
    80004326:	7ee50513          	addi	a0,a0,2030 # 80020b10 <log>
    8000432a:	ffffd097          	auipc	ra,0xffffd
    8000432e:	8c0080e7          	jalr	-1856(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004332:	0001c497          	auipc	s1,0x1c
    80004336:	7de48493          	addi	s1,s1,2014 # 80020b10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000433a:	4979                	li	s2,30
    8000433c:	a039                	j	8000434a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000433e:	85a6                	mv	a1,s1
    80004340:	8526                	mv	a0,s1
    80004342:	ffffe097          	auipc	ra,0xffffe
    80004346:	d28080e7          	jalr	-728(ra) # 8000206a <sleep>
    if(log.committing){
    8000434a:	50dc                	lw	a5,36(s1)
    8000434c:	fbed                	bnez	a5,8000433e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000434e:	509c                	lw	a5,32(s1)
    80004350:	0017871b          	addiw	a4,a5,1
    80004354:	0007069b          	sext.w	a3,a4
    80004358:	0027179b          	slliw	a5,a4,0x2
    8000435c:	9fb9                	addw	a5,a5,a4
    8000435e:	0017979b          	slliw	a5,a5,0x1
    80004362:	54d8                	lw	a4,44(s1)
    80004364:	9fb9                	addw	a5,a5,a4
    80004366:	00f95963          	bge	s2,a5,80004378 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000436a:	85a6                	mv	a1,s1
    8000436c:	8526                	mv	a0,s1
    8000436e:	ffffe097          	auipc	ra,0xffffe
    80004372:	cfc080e7          	jalr	-772(ra) # 8000206a <sleep>
    80004376:	bfd1                	j	8000434a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004378:	0001c517          	auipc	a0,0x1c
    8000437c:	79850513          	addi	a0,a0,1944 # 80020b10 <log>
    80004380:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	91c080e7          	jalr	-1764(ra) # 80000c9e <release>
      break;
    }
  }
}
    8000438a:	60e2                	ld	ra,24(sp)
    8000438c:	6442                	ld	s0,16(sp)
    8000438e:	64a2                	ld	s1,8(sp)
    80004390:	6902                	ld	s2,0(sp)
    80004392:	6105                	addi	sp,sp,32
    80004394:	8082                	ret

0000000080004396 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004396:	7139                	addi	sp,sp,-64
    80004398:	fc06                	sd	ra,56(sp)
    8000439a:	f822                	sd	s0,48(sp)
    8000439c:	f426                	sd	s1,40(sp)
    8000439e:	f04a                	sd	s2,32(sp)
    800043a0:	ec4e                	sd	s3,24(sp)
    800043a2:	e852                	sd	s4,16(sp)
    800043a4:	e456                	sd	s5,8(sp)
    800043a6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043a8:	0001c497          	auipc	s1,0x1c
    800043ac:	76848493          	addi	s1,s1,1896 # 80020b10 <log>
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffd097          	auipc	ra,0xffffd
    800043b6:	838080e7          	jalr	-1992(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800043ba:	509c                	lw	a5,32(s1)
    800043bc:	37fd                	addiw	a5,a5,-1
    800043be:	0007891b          	sext.w	s2,a5
    800043c2:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043c4:	50dc                	lw	a5,36(s1)
    800043c6:	efb9                	bnez	a5,80004424 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043c8:	06091663          	bnez	s2,80004434 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043cc:	0001c497          	auipc	s1,0x1c
    800043d0:	74448493          	addi	s1,s1,1860 # 80020b10 <log>
    800043d4:	4785                	li	a5,1
    800043d6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043d8:	8526                	mv	a0,s1
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	8c4080e7          	jalr	-1852(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043e2:	54dc                	lw	a5,44(s1)
    800043e4:	06f04763          	bgtz	a5,80004452 <end_op+0xbc>
    acquire(&log.lock);
    800043e8:	0001c497          	auipc	s1,0x1c
    800043ec:	72848493          	addi	s1,s1,1832 # 80020b10 <log>
    800043f0:	8526                	mv	a0,s1
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	7f8080e7          	jalr	2040(ra) # 80000bea <acquire>
    log.committing = 0;
    800043fa:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043fe:	8526                	mv	a0,s1
    80004400:	ffffe097          	auipc	ra,0xffffe
    80004404:	cce080e7          	jalr	-818(ra) # 800020ce <wakeup>
    release(&log.lock);
    80004408:	8526                	mv	a0,s1
    8000440a:	ffffd097          	auipc	ra,0xffffd
    8000440e:	894080e7          	jalr	-1900(ra) # 80000c9e <release>
}
    80004412:	70e2                	ld	ra,56(sp)
    80004414:	7442                	ld	s0,48(sp)
    80004416:	74a2                	ld	s1,40(sp)
    80004418:	7902                	ld	s2,32(sp)
    8000441a:	69e2                	ld	s3,24(sp)
    8000441c:	6a42                	ld	s4,16(sp)
    8000441e:	6aa2                	ld	s5,8(sp)
    80004420:	6121                	addi	sp,sp,64
    80004422:	8082                	ret
    panic("log.committing");
    80004424:	00004517          	auipc	a0,0x4
    80004428:	21c50513          	addi	a0,a0,540 # 80008640 <syscalls+0x1f0>
    8000442c:	ffffc097          	auipc	ra,0xffffc
    80004430:	118080e7          	jalr	280(ra) # 80000544 <panic>
    wakeup(&log);
    80004434:	0001c497          	auipc	s1,0x1c
    80004438:	6dc48493          	addi	s1,s1,1756 # 80020b10 <log>
    8000443c:	8526                	mv	a0,s1
    8000443e:	ffffe097          	auipc	ra,0xffffe
    80004442:	c90080e7          	jalr	-880(ra) # 800020ce <wakeup>
  release(&log.lock);
    80004446:	8526                	mv	a0,s1
    80004448:	ffffd097          	auipc	ra,0xffffd
    8000444c:	856080e7          	jalr	-1962(ra) # 80000c9e <release>
  if(do_commit){
    80004450:	b7c9                	j	80004412 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004452:	0001ca97          	auipc	s5,0x1c
    80004456:	6eea8a93          	addi	s5,s5,1774 # 80020b40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000445a:	0001ca17          	auipc	s4,0x1c
    8000445e:	6b6a0a13          	addi	s4,s4,1718 # 80020b10 <log>
    80004462:	018a2583          	lw	a1,24(s4)
    80004466:	012585bb          	addw	a1,a1,s2
    8000446a:	2585                	addiw	a1,a1,1
    8000446c:	028a2503          	lw	a0,40(s4)
    80004470:	fffff097          	auipc	ra,0xfffff
    80004474:	cca080e7          	jalr	-822(ra) # 8000313a <bread>
    80004478:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000447a:	000aa583          	lw	a1,0(s5)
    8000447e:	028a2503          	lw	a0,40(s4)
    80004482:	fffff097          	auipc	ra,0xfffff
    80004486:	cb8080e7          	jalr	-840(ra) # 8000313a <bread>
    8000448a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000448c:	40000613          	li	a2,1024
    80004490:	05850593          	addi	a1,a0,88
    80004494:	05848513          	addi	a0,s1,88
    80004498:	ffffd097          	auipc	ra,0xffffd
    8000449c:	8ae080e7          	jalr	-1874(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800044a0:	8526                	mv	a0,s1
    800044a2:	fffff097          	auipc	ra,0xfffff
    800044a6:	d8a080e7          	jalr	-630(ra) # 8000322c <bwrite>
    brelse(from);
    800044aa:	854e                	mv	a0,s3
    800044ac:	fffff097          	auipc	ra,0xfffff
    800044b0:	dbe080e7          	jalr	-578(ra) # 8000326a <brelse>
    brelse(to);
    800044b4:	8526                	mv	a0,s1
    800044b6:	fffff097          	auipc	ra,0xfffff
    800044ba:	db4080e7          	jalr	-588(ra) # 8000326a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044be:	2905                	addiw	s2,s2,1
    800044c0:	0a91                	addi	s5,s5,4
    800044c2:	02ca2783          	lw	a5,44(s4)
    800044c6:	f8f94ee3          	blt	s2,a5,80004462 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	c6a080e7          	jalr	-918(ra) # 80004134 <write_head>
    install_trans(0); // Now install writes to home locations
    800044d2:	4501                	li	a0,0
    800044d4:	00000097          	auipc	ra,0x0
    800044d8:	cda080e7          	jalr	-806(ra) # 800041ae <install_trans>
    log.lh.n = 0;
    800044dc:	0001c797          	auipc	a5,0x1c
    800044e0:	6607a023          	sw	zero,1632(a5) # 80020b3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044e4:	00000097          	auipc	ra,0x0
    800044e8:	c50080e7          	jalr	-944(ra) # 80004134 <write_head>
    800044ec:	bdf5                	j	800043e8 <end_op+0x52>

00000000800044ee <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044ee:	1101                	addi	sp,sp,-32
    800044f0:	ec06                	sd	ra,24(sp)
    800044f2:	e822                	sd	s0,16(sp)
    800044f4:	e426                	sd	s1,8(sp)
    800044f6:	e04a                	sd	s2,0(sp)
    800044f8:	1000                	addi	s0,sp,32
    800044fa:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044fc:	0001c917          	auipc	s2,0x1c
    80004500:	61490913          	addi	s2,s2,1556 # 80020b10 <log>
    80004504:	854a                	mv	a0,s2
    80004506:	ffffc097          	auipc	ra,0xffffc
    8000450a:	6e4080e7          	jalr	1764(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000450e:	02c92603          	lw	a2,44(s2)
    80004512:	47f5                	li	a5,29
    80004514:	06c7c563          	blt	a5,a2,8000457e <log_write+0x90>
    80004518:	0001c797          	auipc	a5,0x1c
    8000451c:	6147a783          	lw	a5,1556(a5) # 80020b2c <log+0x1c>
    80004520:	37fd                	addiw	a5,a5,-1
    80004522:	04f65e63          	bge	a2,a5,8000457e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004526:	0001c797          	auipc	a5,0x1c
    8000452a:	60a7a783          	lw	a5,1546(a5) # 80020b30 <log+0x20>
    8000452e:	06f05063          	blez	a5,8000458e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004532:	4781                	li	a5,0
    80004534:	06c05563          	blez	a2,8000459e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004538:	44cc                	lw	a1,12(s1)
    8000453a:	0001c717          	auipc	a4,0x1c
    8000453e:	60670713          	addi	a4,a4,1542 # 80020b40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004542:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004544:	4314                	lw	a3,0(a4)
    80004546:	04b68c63          	beq	a3,a1,8000459e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000454a:	2785                	addiw	a5,a5,1
    8000454c:	0711                	addi	a4,a4,4
    8000454e:	fef61be3          	bne	a2,a5,80004544 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004552:	0621                	addi	a2,a2,8
    80004554:	060a                	slli	a2,a2,0x2
    80004556:	0001c797          	auipc	a5,0x1c
    8000455a:	5ba78793          	addi	a5,a5,1466 # 80020b10 <log>
    8000455e:	963e                	add	a2,a2,a5
    80004560:	44dc                	lw	a5,12(s1)
    80004562:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004564:	8526                	mv	a0,s1
    80004566:	fffff097          	auipc	ra,0xfffff
    8000456a:	da2080e7          	jalr	-606(ra) # 80003308 <bpin>
    log.lh.n++;
    8000456e:	0001c717          	auipc	a4,0x1c
    80004572:	5a270713          	addi	a4,a4,1442 # 80020b10 <log>
    80004576:	575c                	lw	a5,44(a4)
    80004578:	2785                	addiw	a5,a5,1
    8000457a:	d75c                	sw	a5,44(a4)
    8000457c:	a835                	j	800045b8 <log_write+0xca>
    panic("too big a transaction");
    8000457e:	00004517          	auipc	a0,0x4
    80004582:	0d250513          	addi	a0,a0,210 # 80008650 <syscalls+0x200>
    80004586:	ffffc097          	auipc	ra,0xffffc
    8000458a:	fbe080e7          	jalr	-66(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000458e:	00004517          	auipc	a0,0x4
    80004592:	0da50513          	addi	a0,a0,218 # 80008668 <syscalls+0x218>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	fae080e7          	jalr	-82(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000459e:	00878713          	addi	a4,a5,8
    800045a2:	00271693          	slli	a3,a4,0x2
    800045a6:	0001c717          	auipc	a4,0x1c
    800045aa:	56a70713          	addi	a4,a4,1386 # 80020b10 <log>
    800045ae:	9736                	add	a4,a4,a3
    800045b0:	44d4                	lw	a3,12(s1)
    800045b2:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045b4:	faf608e3          	beq	a2,a5,80004564 <log_write+0x76>
  }
  release(&log.lock);
    800045b8:	0001c517          	auipc	a0,0x1c
    800045bc:	55850513          	addi	a0,a0,1368 # 80020b10 <log>
    800045c0:	ffffc097          	auipc	ra,0xffffc
    800045c4:	6de080e7          	jalr	1758(ra) # 80000c9e <release>
}
    800045c8:	60e2                	ld	ra,24(sp)
    800045ca:	6442                	ld	s0,16(sp)
    800045cc:	64a2                	ld	s1,8(sp)
    800045ce:	6902                	ld	s2,0(sp)
    800045d0:	6105                	addi	sp,sp,32
    800045d2:	8082                	ret

00000000800045d4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045d4:	1101                	addi	sp,sp,-32
    800045d6:	ec06                	sd	ra,24(sp)
    800045d8:	e822                	sd	s0,16(sp)
    800045da:	e426                	sd	s1,8(sp)
    800045dc:	e04a                	sd	s2,0(sp)
    800045de:	1000                	addi	s0,sp,32
    800045e0:	84aa                	mv	s1,a0
    800045e2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045e4:	00004597          	auipc	a1,0x4
    800045e8:	0a458593          	addi	a1,a1,164 # 80008688 <syscalls+0x238>
    800045ec:	0521                	addi	a0,a0,8
    800045ee:	ffffc097          	auipc	ra,0xffffc
    800045f2:	56c080e7          	jalr	1388(ra) # 80000b5a <initlock>
  lk->name = name;
    800045f6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045fa:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045fe:	0204a423          	sw	zero,40(s1)
}
    80004602:	60e2                	ld	ra,24(sp)
    80004604:	6442                	ld	s0,16(sp)
    80004606:	64a2                	ld	s1,8(sp)
    80004608:	6902                	ld	s2,0(sp)
    8000460a:	6105                	addi	sp,sp,32
    8000460c:	8082                	ret

000000008000460e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000460e:	1101                	addi	sp,sp,-32
    80004610:	ec06                	sd	ra,24(sp)
    80004612:	e822                	sd	s0,16(sp)
    80004614:	e426                	sd	s1,8(sp)
    80004616:	e04a                	sd	s2,0(sp)
    80004618:	1000                	addi	s0,sp,32
    8000461a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000461c:	00850913          	addi	s2,a0,8
    80004620:	854a                	mv	a0,s2
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	5c8080e7          	jalr	1480(ra) # 80000bea <acquire>
  while (lk->locked) {
    8000462a:	409c                	lw	a5,0(s1)
    8000462c:	cb89                	beqz	a5,8000463e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000462e:	85ca                	mv	a1,s2
    80004630:	8526                	mv	a0,s1
    80004632:	ffffe097          	auipc	ra,0xffffe
    80004636:	a38080e7          	jalr	-1480(ra) # 8000206a <sleep>
  while (lk->locked) {
    8000463a:	409c                	lw	a5,0(s1)
    8000463c:	fbed                	bnez	a5,8000462e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000463e:	4785                	li	a5,1
    80004640:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004642:	ffffd097          	auipc	ra,0xffffd
    80004646:	384080e7          	jalr	900(ra) # 800019c6 <myproc>
    8000464a:	591c                	lw	a5,48(a0)
    8000464c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000464e:	854a                	mv	a0,s2
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	64e080e7          	jalr	1614(ra) # 80000c9e <release>
}
    80004658:	60e2                	ld	ra,24(sp)
    8000465a:	6442                	ld	s0,16(sp)
    8000465c:	64a2                	ld	s1,8(sp)
    8000465e:	6902                	ld	s2,0(sp)
    80004660:	6105                	addi	sp,sp,32
    80004662:	8082                	ret

0000000080004664 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004664:	1101                	addi	sp,sp,-32
    80004666:	ec06                	sd	ra,24(sp)
    80004668:	e822                	sd	s0,16(sp)
    8000466a:	e426                	sd	s1,8(sp)
    8000466c:	e04a                	sd	s2,0(sp)
    8000466e:	1000                	addi	s0,sp,32
    80004670:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004672:	00850913          	addi	s2,a0,8
    80004676:	854a                	mv	a0,s2
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	572080e7          	jalr	1394(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004680:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004684:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004688:	8526                	mv	a0,s1
    8000468a:	ffffe097          	auipc	ra,0xffffe
    8000468e:	a44080e7          	jalr	-1468(ra) # 800020ce <wakeup>
  release(&lk->lk);
    80004692:	854a                	mv	a0,s2
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	60a080e7          	jalr	1546(ra) # 80000c9e <release>
}
    8000469c:	60e2                	ld	ra,24(sp)
    8000469e:	6442                	ld	s0,16(sp)
    800046a0:	64a2                	ld	s1,8(sp)
    800046a2:	6902                	ld	s2,0(sp)
    800046a4:	6105                	addi	sp,sp,32
    800046a6:	8082                	ret

00000000800046a8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046a8:	7179                	addi	sp,sp,-48
    800046aa:	f406                	sd	ra,40(sp)
    800046ac:	f022                	sd	s0,32(sp)
    800046ae:	ec26                	sd	s1,24(sp)
    800046b0:	e84a                	sd	s2,16(sp)
    800046b2:	e44e                	sd	s3,8(sp)
    800046b4:	1800                	addi	s0,sp,48
    800046b6:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046b8:	00850913          	addi	s2,a0,8
    800046bc:	854a                	mv	a0,s2
    800046be:	ffffc097          	auipc	ra,0xffffc
    800046c2:	52c080e7          	jalr	1324(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046c6:	409c                	lw	a5,0(s1)
    800046c8:	ef99                	bnez	a5,800046e6 <holdingsleep+0x3e>
    800046ca:	4481                	li	s1,0
  release(&lk->lk);
    800046cc:	854a                	mv	a0,s2
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	5d0080e7          	jalr	1488(ra) # 80000c9e <release>
  return r;
}
    800046d6:	8526                	mv	a0,s1
    800046d8:	70a2                	ld	ra,40(sp)
    800046da:	7402                	ld	s0,32(sp)
    800046dc:	64e2                	ld	s1,24(sp)
    800046de:	6942                	ld	s2,16(sp)
    800046e0:	69a2                	ld	s3,8(sp)
    800046e2:	6145                	addi	sp,sp,48
    800046e4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046e6:	0284a983          	lw	s3,40(s1)
    800046ea:	ffffd097          	auipc	ra,0xffffd
    800046ee:	2dc080e7          	jalr	732(ra) # 800019c6 <myproc>
    800046f2:	5904                	lw	s1,48(a0)
    800046f4:	413484b3          	sub	s1,s1,s3
    800046f8:	0014b493          	seqz	s1,s1
    800046fc:	bfc1                	j	800046cc <holdingsleep+0x24>

00000000800046fe <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046fe:	1141                	addi	sp,sp,-16
    80004700:	e406                	sd	ra,8(sp)
    80004702:	e022                	sd	s0,0(sp)
    80004704:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004706:	00004597          	auipc	a1,0x4
    8000470a:	f9258593          	addi	a1,a1,-110 # 80008698 <syscalls+0x248>
    8000470e:	0001c517          	auipc	a0,0x1c
    80004712:	54a50513          	addi	a0,a0,1354 # 80020c58 <ftable>
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	444080e7          	jalr	1092(ra) # 80000b5a <initlock>
}
    8000471e:	60a2                	ld	ra,8(sp)
    80004720:	6402                	ld	s0,0(sp)
    80004722:	0141                	addi	sp,sp,16
    80004724:	8082                	ret

0000000080004726 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004726:	1101                	addi	sp,sp,-32
    80004728:	ec06                	sd	ra,24(sp)
    8000472a:	e822                	sd	s0,16(sp)
    8000472c:	e426                	sd	s1,8(sp)
    8000472e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004730:	0001c517          	auipc	a0,0x1c
    80004734:	52850513          	addi	a0,a0,1320 # 80020c58 <ftable>
    80004738:	ffffc097          	auipc	ra,0xffffc
    8000473c:	4b2080e7          	jalr	1202(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004740:	0001c497          	auipc	s1,0x1c
    80004744:	53048493          	addi	s1,s1,1328 # 80020c70 <ftable+0x18>
    80004748:	0001d717          	auipc	a4,0x1d
    8000474c:	4c870713          	addi	a4,a4,1224 # 80021c10 <disk>
    if(f->ref == 0){
    80004750:	40dc                	lw	a5,4(s1)
    80004752:	cf99                	beqz	a5,80004770 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004754:	02848493          	addi	s1,s1,40
    80004758:	fee49ce3          	bne	s1,a4,80004750 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000475c:	0001c517          	auipc	a0,0x1c
    80004760:	4fc50513          	addi	a0,a0,1276 # 80020c58 <ftable>
    80004764:	ffffc097          	auipc	ra,0xffffc
    80004768:	53a080e7          	jalr	1338(ra) # 80000c9e <release>
  return 0;
    8000476c:	4481                	li	s1,0
    8000476e:	a819                	j	80004784 <filealloc+0x5e>
      f->ref = 1;
    80004770:	4785                	li	a5,1
    80004772:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004774:	0001c517          	auipc	a0,0x1c
    80004778:	4e450513          	addi	a0,a0,1252 # 80020c58 <ftable>
    8000477c:	ffffc097          	auipc	ra,0xffffc
    80004780:	522080e7          	jalr	1314(ra) # 80000c9e <release>
}
    80004784:	8526                	mv	a0,s1
    80004786:	60e2                	ld	ra,24(sp)
    80004788:	6442                	ld	s0,16(sp)
    8000478a:	64a2                	ld	s1,8(sp)
    8000478c:	6105                	addi	sp,sp,32
    8000478e:	8082                	ret

0000000080004790 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004790:	1101                	addi	sp,sp,-32
    80004792:	ec06                	sd	ra,24(sp)
    80004794:	e822                	sd	s0,16(sp)
    80004796:	e426                	sd	s1,8(sp)
    80004798:	1000                	addi	s0,sp,32
    8000479a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000479c:	0001c517          	auipc	a0,0x1c
    800047a0:	4bc50513          	addi	a0,a0,1212 # 80020c58 <ftable>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	446080e7          	jalr	1094(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800047ac:	40dc                	lw	a5,4(s1)
    800047ae:	02f05263          	blez	a5,800047d2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047b2:	2785                	addiw	a5,a5,1
    800047b4:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047b6:	0001c517          	auipc	a0,0x1c
    800047ba:	4a250513          	addi	a0,a0,1186 # 80020c58 <ftable>
    800047be:	ffffc097          	auipc	ra,0xffffc
    800047c2:	4e0080e7          	jalr	1248(ra) # 80000c9e <release>
  return f;
}
    800047c6:	8526                	mv	a0,s1
    800047c8:	60e2                	ld	ra,24(sp)
    800047ca:	6442                	ld	s0,16(sp)
    800047cc:	64a2                	ld	s1,8(sp)
    800047ce:	6105                	addi	sp,sp,32
    800047d0:	8082                	ret
    panic("filedup");
    800047d2:	00004517          	auipc	a0,0x4
    800047d6:	ece50513          	addi	a0,a0,-306 # 800086a0 <syscalls+0x250>
    800047da:	ffffc097          	auipc	ra,0xffffc
    800047de:	d6a080e7          	jalr	-662(ra) # 80000544 <panic>

00000000800047e2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047e2:	7139                	addi	sp,sp,-64
    800047e4:	fc06                	sd	ra,56(sp)
    800047e6:	f822                	sd	s0,48(sp)
    800047e8:	f426                	sd	s1,40(sp)
    800047ea:	f04a                	sd	s2,32(sp)
    800047ec:	ec4e                	sd	s3,24(sp)
    800047ee:	e852                	sd	s4,16(sp)
    800047f0:	e456                	sd	s5,8(sp)
    800047f2:	0080                	addi	s0,sp,64
    800047f4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047f6:	0001c517          	auipc	a0,0x1c
    800047fa:	46250513          	addi	a0,a0,1122 # 80020c58 <ftable>
    800047fe:	ffffc097          	auipc	ra,0xffffc
    80004802:	3ec080e7          	jalr	1004(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004806:	40dc                	lw	a5,4(s1)
    80004808:	06f05163          	blez	a5,8000486a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000480c:	37fd                	addiw	a5,a5,-1
    8000480e:	0007871b          	sext.w	a4,a5
    80004812:	c0dc                	sw	a5,4(s1)
    80004814:	06e04363          	bgtz	a4,8000487a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004818:	0004a903          	lw	s2,0(s1)
    8000481c:	0094ca83          	lbu	s5,9(s1)
    80004820:	0104ba03          	ld	s4,16(s1)
    80004824:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004828:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000482c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004830:	0001c517          	auipc	a0,0x1c
    80004834:	42850513          	addi	a0,a0,1064 # 80020c58 <ftable>
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	466080e7          	jalr	1126(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004840:	4785                	li	a5,1
    80004842:	04f90d63          	beq	s2,a5,8000489c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004846:	3979                	addiw	s2,s2,-2
    80004848:	4785                	li	a5,1
    8000484a:	0527e063          	bltu	a5,s2,8000488a <fileclose+0xa8>
    begin_op();
    8000484e:	00000097          	auipc	ra,0x0
    80004852:	ac8080e7          	jalr	-1336(ra) # 80004316 <begin_op>
    iput(ff.ip);
    80004856:	854e                	mv	a0,s3
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	2b6080e7          	jalr	694(ra) # 80003b0e <iput>
    end_op();
    80004860:	00000097          	auipc	ra,0x0
    80004864:	b36080e7          	jalr	-1226(ra) # 80004396 <end_op>
    80004868:	a00d                	j	8000488a <fileclose+0xa8>
    panic("fileclose");
    8000486a:	00004517          	auipc	a0,0x4
    8000486e:	e3e50513          	addi	a0,a0,-450 # 800086a8 <syscalls+0x258>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	cd2080e7          	jalr	-814(ra) # 80000544 <panic>
    release(&ftable.lock);
    8000487a:	0001c517          	auipc	a0,0x1c
    8000487e:	3de50513          	addi	a0,a0,990 # 80020c58 <ftable>
    80004882:	ffffc097          	auipc	ra,0xffffc
    80004886:	41c080e7          	jalr	1052(ra) # 80000c9e <release>
  }
}
    8000488a:	70e2                	ld	ra,56(sp)
    8000488c:	7442                	ld	s0,48(sp)
    8000488e:	74a2                	ld	s1,40(sp)
    80004890:	7902                	ld	s2,32(sp)
    80004892:	69e2                	ld	s3,24(sp)
    80004894:	6a42                	ld	s4,16(sp)
    80004896:	6aa2                	ld	s5,8(sp)
    80004898:	6121                	addi	sp,sp,64
    8000489a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000489c:	85d6                	mv	a1,s5
    8000489e:	8552                	mv	a0,s4
    800048a0:	00000097          	auipc	ra,0x0
    800048a4:	34c080e7          	jalr	844(ra) # 80004bec <pipeclose>
    800048a8:	b7cd                	j	8000488a <fileclose+0xa8>

00000000800048aa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048aa:	715d                	addi	sp,sp,-80
    800048ac:	e486                	sd	ra,72(sp)
    800048ae:	e0a2                	sd	s0,64(sp)
    800048b0:	fc26                	sd	s1,56(sp)
    800048b2:	f84a                	sd	s2,48(sp)
    800048b4:	f44e                	sd	s3,40(sp)
    800048b6:	0880                	addi	s0,sp,80
    800048b8:	84aa                	mv	s1,a0
    800048ba:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048bc:	ffffd097          	auipc	ra,0xffffd
    800048c0:	10a080e7          	jalr	266(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048c4:	409c                	lw	a5,0(s1)
    800048c6:	37f9                	addiw	a5,a5,-2
    800048c8:	4705                	li	a4,1
    800048ca:	04f76763          	bltu	a4,a5,80004918 <filestat+0x6e>
    800048ce:	892a                	mv	s2,a0
    ilock(f->ip);
    800048d0:	6c88                	ld	a0,24(s1)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	082080e7          	jalr	130(ra) # 80003954 <ilock>
    stati(f->ip, &st);
    800048da:	fb840593          	addi	a1,s0,-72
    800048de:	6c88                	ld	a0,24(s1)
    800048e0:	fffff097          	auipc	ra,0xfffff
    800048e4:	2fe080e7          	jalr	766(ra) # 80003bde <stati>
    iunlock(f->ip);
    800048e8:	6c88                	ld	a0,24(s1)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	12c080e7          	jalr	300(ra) # 80003a16 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048f2:	46e1                	li	a3,24
    800048f4:	fb840613          	addi	a2,s0,-72
    800048f8:	85ce                	mv	a1,s3
    800048fa:	05093503          	ld	a0,80(s2)
    800048fe:	ffffd097          	auipc	ra,0xffffd
    80004902:	d86080e7          	jalr	-634(ra) # 80001684 <copyout>
    80004906:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000490a:	60a6                	ld	ra,72(sp)
    8000490c:	6406                	ld	s0,64(sp)
    8000490e:	74e2                	ld	s1,56(sp)
    80004910:	7942                	ld	s2,48(sp)
    80004912:	79a2                	ld	s3,40(sp)
    80004914:	6161                	addi	sp,sp,80
    80004916:	8082                	ret
  return -1;
    80004918:	557d                	li	a0,-1
    8000491a:	bfc5                	j	8000490a <filestat+0x60>

000000008000491c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000491c:	7179                	addi	sp,sp,-48
    8000491e:	f406                	sd	ra,40(sp)
    80004920:	f022                	sd	s0,32(sp)
    80004922:	ec26                	sd	s1,24(sp)
    80004924:	e84a                	sd	s2,16(sp)
    80004926:	e44e                	sd	s3,8(sp)
    80004928:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000492a:	00854783          	lbu	a5,8(a0)
    8000492e:	c3d5                	beqz	a5,800049d2 <fileread+0xb6>
    80004930:	84aa                	mv	s1,a0
    80004932:	89ae                	mv	s3,a1
    80004934:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004936:	411c                	lw	a5,0(a0)
    80004938:	4705                	li	a4,1
    8000493a:	04e78963          	beq	a5,a4,8000498c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000493e:	470d                	li	a4,3
    80004940:	04e78d63          	beq	a5,a4,8000499a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004944:	4709                	li	a4,2
    80004946:	06e79e63          	bne	a5,a4,800049c2 <fileread+0xa6>
    ilock(f->ip);
    8000494a:	6d08                	ld	a0,24(a0)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	008080e7          	jalr	8(ra) # 80003954 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004954:	874a                	mv	a4,s2
    80004956:	5094                	lw	a3,32(s1)
    80004958:	864e                	mv	a2,s3
    8000495a:	4585                	li	a1,1
    8000495c:	6c88                	ld	a0,24(s1)
    8000495e:	fffff097          	auipc	ra,0xfffff
    80004962:	2aa080e7          	jalr	682(ra) # 80003c08 <readi>
    80004966:	892a                	mv	s2,a0
    80004968:	00a05563          	blez	a0,80004972 <fileread+0x56>
      f->off += r;
    8000496c:	509c                	lw	a5,32(s1)
    8000496e:	9fa9                	addw	a5,a5,a0
    80004970:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004972:	6c88                	ld	a0,24(s1)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	0a2080e7          	jalr	162(ra) # 80003a16 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000497c:	854a                	mv	a0,s2
    8000497e:	70a2                	ld	ra,40(sp)
    80004980:	7402                	ld	s0,32(sp)
    80004982:	64e2                	ld	s1,24(sp)
    80004984:	6942                	ld	s2,16(sp)
    80004986:	69a2                	ld	s3,8(sp)
    80004988:	6145                	addi	sp,sp,48
    8000498a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000498c:	6908                	ld	a0,16(a0)
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	3ce080e7          	jalr	974(ra) # 80004d5c <piperead>
    80004996:	892a                	mv	s2,a0
    80004998:	b7d5                	j	8000497c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000499a:	02451783          	lh	a5,36(a0)
    8000499e:	03079693          	slli	a3,a5,0x30
    800049a2:	92c1                	srli	a3,a3,0x30
    800049a4:	4725                	li	a4,9
    800049a6:	02d76863          	bltu	a4,a3,800049d6 <fileread+0xba>
    800049aa:	0792                	slli	a5,a5,0x4
    800049ac:	0001c717          	auipc	a4,0x1c
    800049b0:	20c70713          	addi	a4,a4,524 # 80020bb8 <devsw>
    800049b4:	97ba                	add	a5,a5,a4
    800049b6:	639c                	ld	a5,0(a5)
    800049b8:	c38d                	beqz	a5,800049da <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049ba:	4505                	li	a0,1
    800049bc:	9782                	jalr	a5
    800049be:	892a                	mv	s2,a0
    800049c0:	bf75                	j	8000497c <fileread+0x60>
    panic("fileread");
    800049c2:	00004517          	auipc	a0,0x4
    800049c6:	cf650513          	addi	a0,a0,-778 # 800086b8 <syscalls+0x268>
    800049ca:	ffffc097          	auipc	ra,0xffffc
    800049ce:	b7a080e7          	jalr	-1158(ra) # 80000544 <panic>
    return -1;
    800049d2:	597d                	li	s2,-1
    800049d4:	b765                	j	8000497c <fileread+0x60>
      return -1;
    800049d6:	597d                	li	s2,-1
    800049d8:	b755                	j	8000497c <fileread+0x60>
    800049da:	597d                	li	s2,-1
    800049dc:	b745                	j	8000497c <fileread+0x60>

00000000800049de <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049de:	715d                	addi	sp,sp,-80
    800049e0:	e486                	sd	ra,72(sp)
    800049e2:	e0a2                	sd	s0,64(sp)
    800049e4:	fc26                	sd	s1,56(sp)
    800049e6:	f84a                	sd	s2,48(sp)
    800049e8:	f44e                	sd	s3,40(sp)
    800049ea:	f052                	sd	s4,32(sp)
    800049ec:	ec56                	sd	s5,24(sp)
    800049ee:	e85a                	sd	s6,16(sp)
    800049f0:	e45e                	sd	s7,8(sp)
    800049f2:	e062                	sd	s8,0(sp)
    800049f4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049f6:	00954783          	lbu	a5,9(a0)
    800049fa:	10078663          	beqz	a5,80004b06 <filewrite+0x128>
    800049fe:	892a                	mv	s2,a0
    80004a00:	8aae                	mv	s5,a1
    80004a02:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a04:	411c                	lw	a5,0(a0)
    80004a06:	4705                	li	a4,1
    80004a08:	02e78263          	beq	a5,a4,80004a2c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a0c:	470d                	li	a4,3
    80004a0e:	02e78663          	beq	a5,a4,80004a3a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a12:	4709                	li	a4,2
    80004a14:	0ee79163          	bne	a5,a4,80004af6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a18:	0ac05d63          	blez	a2,80004ad2 <filewrite+0xf4>
    int i = 0;
    80004a1c:	4981                	li	s3,0
    80004a1e:	6b05                	lui	s6,0x1
    80004a20:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a24:	6b85                	lui	s7,0x1
    80004a26:	c00b8b9b          	addiw	s7,s7,-1024
    80004a2a:	a861                	j	80004ac2 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a2c:	6908                	ld	a0,16(a0)
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	22e080e7          	jalr	558(ra) # 80004c5c <pipewrite>
    80004a36:	8a2a                	mv	s4,a0
    80004a38:	a045                	j	80004ad8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a3a:	02451783          	lh	a5,36(a0)
    80004a3e:	03079693          	slli	a3,a5,0x30
    80004a42:	92c1                	srli	a3,a3,0x30
    80004a44:	4725                	li	a4,9
    80004a46:	0cd76263          	bltu	a4,a3,80004b0a <filewrite+0x12c>
    80004a4a:	0792                	slli	a5,a5,0x4
    80004a4c:	0001c717          	auipc	a4,0x1c
    80004a50:	16c70713          	addi	a4,a4,364 # 80020bb8 <devsw>
    80004a54:	97ba                	add	a5,a5,a4
    80004a56:	679c                	ld	a5,8(a5)
    80004a58:	cbdd                	beqz	a5,80004b0e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a5a:	4505                	li	a0,1
    80004a5c:	9782                	jalr	a5
    80004a5e:	8a2a                	mv	s4,a0
    80004a60:	a8a5                	j	80004ad8 <filewrite+0xfa>
    80004a62:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a66:	00000097          	auipc	ra,0x0
    80004a6a:	8b0080e7          	jalr	-1872(ra) # 80004316 <begin_op>
      ilock(f->ip);
    80004a6e:	01893503          	ld	a0,24(s2)
    80004a72:	fffff097          	auipc	ra,0xfffff
    80004a76:	ee2080e7          	jalr	-286(ra) # 80003954 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a7a:	8762                	mv	a4,s8
    80004a7c:	02092683          	lw	a3,32(s2)
    80004a80:	01598633          	add	a2,s3,s5
    80004a84:	4585                	li	a1,1
    80004a86:	01893503          	ld	a0,24(s2)
    80004a8a:	fffff097          	auipc	ra,0xfffff
    80004a8e:	276080e7          	jalr	630(ra) # 80003d00 <writei>
    80004a92:	84aa                	mv	s1,a0
    80004a94:	00a05763          	blez	a0,80004aa2 <filewrite+0xc4>
        f->off += r;
    80004a98:	02092783          	lw	a5,32(s2)
    80004a9c:	9fa9                	addw	a5,a5,a0
    80004a9e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004aa2:	01893503          	ld	a0,24(s2)
    80004aa6:	fffff097          	auipc	ra,0xfffff
    80004aaa:	f70080e7          	jalr	-144(ra) # 80003a16 <iunlock>
      end_op();
    80004aae:	00000097          	auipc	ra,0x0
    80004ab2:	8e8080e7          	jalr	-1816(ra) # 80004396 <end_op>

      if(r != n1){
    80004ab6:	009c1f63          	bne	s8,s1,80004ad4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004aba:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004abe:	0149db63          	bge	s3,s4,80004ad4 <filewrite+0xf6>
      int n1 = n - i;
    80004ac2:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004ac6:	84be                	mv	s1,a5
    80004ac8:	2781                	sext.w	a5,a5
    80004aca:	f8fb5ce3          	bge	s6,a5,80004a62 <filewrite+0x84>
    80004ace:	84de                	mv	s1,s7
    80004ad0:	bf49                	j	80004a62 <filewrite+0x84>
    int i = 0;
    80004ad2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004ad4:	013a1f63          	bne	s4,s3,80004af2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004ad8:	8552                	mv	a0,s4
    80004ada:	60a6                	ld	ra,72(sp)
    80004adc:	6406                	ld	s0,64(sp)
    80004ade:	74e2                	ld	s1,56(sp)
    80004ae0:	7942                	ld	s2,48(sp)
    80004ae2:	79a2                	ld	s3,40(sp)
    80004ae4:	7a02                	ld	s4,32(sp)
    80004ae6:	6ae2                	ld	s5,24(sp)
    80004ae8:	6b42                	ld	s6,16(sp)
    80004aea:	6ba2                	ld	s7,8(sp)
    80004aec:	6c02                	ld	s8,0(sp)
    80004aee:	6161                	addi	sp,sp,80
    80004af0:	8082                	ret
    ret = (i == n ? n : -1);
    80004af2:	5a7d                	li	s4,-1
    80004af4:	b7d5                	j	80004ad8 <filewrite+0xfa>
    panic("filewrite");
    80004af6:	00004517          	auipc	a0,0x4
    80004afa:	bd250513          	addi	a0,a0,-1070 # 800086c8 <syscalls+0x278>
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	a46080e7          	jalr	-1466(ra) # 80000544 <panic>
    return -1;
    80004b06:	5a7d                	li	s4,-1
    80004b08:	bfc1                	j	80004ad8 <filewrite+0xfa>
      return -1;
    80004b0a:	5a7d                	li	s4,-1
    80004b0c:	b7f1                	j	80004ad8 <filewrite+0xfa>
    80004b0e:	5a7d                	li	s4,-1
    80004b10:	b7e1                	j	80004ad8 <filewrite+0xfa>

0000000080004b12 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b12:	7179                	addi	sp,sp,-48
    80004b14:	f406                	sd	ra,40(sp)
    80004b16:	f022                	sd	s0,32(sp)
    80004b18:	ec26                	sd	s1,24(sp)
    80004b1a:	e84a                	sd	s2,16(sp)
    80004b1c:	e44e                	sd	s3,8(sp)
    80004b1e:	e052                	sd	s4,0(sp)
    80004b20:	1800                	addi	s0,sp,48
    80004b22:	84aa                	mv	s1,a0
    80004b24:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b26:	0005b023          	sd	zero,0(a1)
    80004b2a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	bf8080e7          	jalr	-1032(ra) # 80004726 <filealloc>
    80004b36:	e088                	sd	a0,0(s1)
    80004b38:	c551                	beqz	a0,80004bc4 <pipealloc+0xb2>
    80004b3a:	00000097          	auipc	ra,0x0
    80004b3e:	bec080e7          	jalr	-1044(ra) # 80004726 <filealloc>
    80004b42:	00aa3023          	sd	a0,0(s4)
    80004b46:	c92d                	beqz	a0,80004bb8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b48:	ffffc097          	auipc	ra,0xffffc
    80004b4c:	fb2080e7          	jalr	-78(ra) # 80000afa <kalloc>
    80004b50:	892a                	mv	s2,a0
    80004b52:	c125                	beqz	a0,80004bb2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b54:	4985                	li	s3,1
    80004b56:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b5a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b5e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b62:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b66:	00004597          	auipc	a1,0x4
    80004b6a:	b7258593          	addi	a1,a1,-1166 # 800086d8 <syscalls+0x288>
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	fec080e7          	jalr	-20(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004b76:	609c                	ld	a5,0(s1)
    80004b78:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b7c:	609c                	ld	a5,0(s1)
    80004b7e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b82:	609c                	ld	a5,0(s1)
    80004b84:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b88:	609c                	ld	a5,0(s1)
    80004b8a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b8e:	000a3783          	ld	a5,0(s4)
    80004b92:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b96:	000a3783          	ld	a5,0(s4)
    80004b9a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b9e:	000a3783          	ld	a5,0(s4)
    80004ba2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ba6:	000a3783          	ld	a5,0(s4)
    80004baa:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bae:	4501                	li	a0,0
    80004bb0:	a025                	j	80004bd8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bb2:	6088                	ld	a0,0(s1)
    80004bb4:	e501                	bnez	a0,80004bbc <pipealloc+0xaa>
    80004bb6:	a039                	j	80004bc4 <pipealloc+0xb2>
    80004bb8:	6088                	ld	a0,0(s1)
    80004bba:	c51d                	beqz	a0,80004be8 <pipealloc+0xd6>
    fileclose(*f0);
    80004bbc:	00000097          	auipc	ra,0x0
    80004bc0:	c26080e7          	jalr	-986(ra) # 800047e2 <fileclose>
  if(*f1)
    80004bc4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bc8:	557d                	li	a0,-1
  if(*f1)
    80004bca:	c799                	beqz	a5,80004bd8 <pipealloc+0xc6>
    fileclose(*f1);
    80004bcc:	853e                	mv	a0,a5
    80004bce:	00000097          	auipc	ra,0x0
    80004bd2:	c14080e7          	jalr	-1004(ra) # 800047e2 <fileclose>
  return -1;
    80004bd6:	557d                	li	a0,-1
}
    80004bd8:	70a2                	ld	ra,40(sp)
    80004bda:	7402                	ld	s0,32(sp)
    80004bdc:	64e2                	ld	s1,24(sp)
    80004bde:	6942                	ld	s2,16(sp)
    80004be0:	69a2                	ld	s3,8(sp)
    80004be2:	6a02                	ld	s4,0(sp)
    80004be4:	6145                	addi	sp,sp,48
    80004be6:	8082                	ret
  return -1;
    80004be8:	557d                	li	a0,-1
    80004bea:	b7fd                	j	80004bd8 <pipealloc+0xc6>

0000000080004bec <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bec:	1101                	addi	sp,sp,-32
    80004bee:	ec06                	sd	ra,24(sp)
    80004bf0:	e822                	sd	s0,16(sp)
    80004bf2:	e426                	sd	s1,8(sp)
    80004bf4:	e04a                	sd	s2,0(sp)
    80004bf6:	1000                	addi	s0,sp,32
    80004bf8:	84aa                	mv	s1,a0
    80004bfa:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bfc:	ffffc097          	auipc	ra,0xffffc
    80004c00:	fee080e7          	jalr	-18(ra) # 80000bea <acquire>
  if(writable){
    80004c04:	02090d63          	beqz	s2,80004c3e <pipeclose+0x52>
    pi->writeopen = 0;
    80004c08:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c0c:	21848513          	addi	a0,s1,536
    80004c10:	ffffd097          	auipc	ra,0xffffd
    80004c14:	4be080e7          	jalr	1214(ra) # 800020ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c18:	2204b783          	ld	a5,544(s1)
    80004c1c:	eb95                	bnez	a5,80004c50 <pipeclose+0x64>
    release(&pi->lock);
    80004c1e:	8526                	mv	a0,s1
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	07e080e7          	jalr	126(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004c28:	8526                	mv	a0,s1
    80004c2a:	ffffc097          	auipc	ra,0xffffc
    80004c2e:	dd4080e7          	jalr	-556(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004c32:	60e2                	ld	ra,24(sp)
    80004c34:	6442                	ld	s0,16(sp)
    80004c36:	64a2                	ld	s1,8(sp)
    80004c38:	6902                	ld	s2,0(sp)
    80004c3a:	6105                	addi	sp,sp,32
    80004c3c:	8082                	ret
    pi->readopen = 0;
    80004c3e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c42:	21c48513          	addi	a0,s1,540
    80004c46:	ffffd097          	auipc	ra,0xffffd
    80004c4a:	488080e7          	jalr	1160(ra) # 800020ce <wakeup>
    80004c4e:	b7e9                	j	80004c18 <pipeclose+0x2c>
    release(&pi->lock);
    80004c50:	8526                	mv	a0,s1
    80004c52:	ffffc097          	auipc	ra,0xffffc
    80004c56:	04c080e7          	jalr	76(ra) # 80000c9e <release>
}
    80004c5a:	bfe1                	j	80004c32 <pipeclose+0x46>

0000000080004c5c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c5c:	7159                	addi	sp,sp,-112
    80004c5e:	f486                	sd	ra,104(sp)
    80004c60:	f0a2                	sd	s0,96(sp)
    80004c62:	eca6                	sd	s1,88(sp)
    80004c64:	e8ca                	sd	s2,80(sp)
    80004c66:	e4ce                	sd	s3,72(sp)
    80004c68:	e0d2                	sd	s4,64(sp)
    80004c6a:	fc56                	sd	s5,56(sp)
    80004c6c:	f85a                	sd	s6,48(sp)
    80004c6e:	f45e                	sd	s7,40(sp)
    80004c70:	f062                	sd	s8,32(sp)
    80004c72:	ec66                	sd	s9,24(sp)
    80004c74:	1880                	addi	s0,sp,112
    80004c76:	84aa                	mv	s1,a0
    80004c78:	8aae                	mv	s5,a1
    80004c7a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c7c:	ffffd097          	auipc	ra,0xffffd
    80004c80:	d4a080e7          	jalr	-694(ra) # 800019c6 <myproc>
    80004c84:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c86:	8526                	mv	a0,s1
    80004c88:	ffffc097          	auipc	ra,0xffffc
    80004c8c:	f62080e7          	jalr	-158(ra) # 80000bea <acquire>
  while(i < n){
    80004c90:	0d405463          	blez	s4,80004d58 <pipewrite+0xfc>
    80004c94:	8ba6                	mv	s7,s1
  int i = 0;
    80004c96:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c98:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c9a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c9e:	21c48c13          	addi	s8,s1,540
    80004ca2:	a08d                	j	80004d04 <pipewrite+0xa8>
      release(&pi->lock);
    80004ca4:	8526                	mv	a0,s1
    80004ca6:	ffffc097          	auipc	ra,0xffffc
    80004caa:	ff8080e7          	jalr	-8(ra) # 80000c9e <release>
      return -1;
    80004cae:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cb0:	854a                	mv	a0,s2
    80004cb2:	70a6                	ld	ra,104(sp)
    80004cb4:	7406                	ld	s0,96(sp)
    80004cb6:	64e6                	ld	s1,88(sp)
    80004cb8:	6946                	ld	s2,80(sp)
    80004cba:	69a6                	ld	s3,72(sp)
    80004cbc:	6a06                	ld	s4,64(sp)
    80004cbe:	7ae2                	ld	s5,56(sp)
    80004cc0:	7b42                	ld	s6,48(sp)
    80004cc2:	7ba2                	ld	s7,40(sp)
    80004cc4:	7c02                	ld	s8,32(sp)
    80004cc6:	6ce2                	ld	s9,24(sp)
    80004cc8:	6165                	addi	sp,sp,112
    80004cca:	8082                	ret
      wakeup(&pi->nread);
    80004ccc:	8566                	mv	a0,s9
    80004cce:	ffffd097          	auipc	ra,0xffffd
    80004cd2:	400080e7          	jalr	1024(ra) # 800020ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cd6:	85de                	mv	a1,s7
    80004cd8:	8562                	mv	a0,s8
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	390080e7          	jalr	912(ra) # 8000206a <sleep>
    80004ce2:	a839                	j	80004d00 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ce4:	21c4a783          	lw	a5,540(s1)
    80004ce8:	0017871b          	addiw	a4,a5,1
    80004cec:	20e4ae23          	sw	a4,540(s1)
    80004cf0:	1ff7f793          	andi	a5,a5,511
    80004cf4:	97a6                	add	a5,a5,s1
    80004cf6:	f9f44703          	lbu	a4,-97(s0)
    80004cfa:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cfe:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d00:	05495063          	bge	s2,s4,80004d40 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004d04:	2204a783          	lw	a5,544(s1)
    80004d08:	dfd1                	beqz	a5,80004ca4 <pipewrite+0x48>
    80004d0a:	854e                	mv	a0,s3
    80004d0c:	ffffd097          	auipc	ra,0xffffd
    80004d10:	606080e7          	jalr	1542(ra) # 80002312 <killed>
    80004d14:	f941                	bnez	a0,80004ca4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d16:	2184a783          	lw	a5,536(s1)
    80004d1a:	21c4a703          	lw	a4,540(s1)
    80004d1e:	2007879b          	addiw	a5,a5,512
    80004d22:	faf705e3          	beq	a4,a5,80004ccc <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d26:	4685                	li	a3,1
    80004d28:	01590633          	add	a2,s2,s5
    80004d2c:	f9f40593          	addi	a1,s0,-97
    80004d30:	0509b503          	ld	a0,80(s3)
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	9dc080e7          	jalr	-1572(ra) # 80001710 <copyin>
    80004d3c:	fb6514e3          	bne	a0,s6,80004ce4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d40:	21848513          	addi	a0,s1,536
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	38a080e7          	jalr	906(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004d4c:	8526                	mv	a0,s1
    80004d4e:	ffffc097          	auipc	ra,0xffffc
    80004d52:	f50080e7          	jalr	-176(ra) # 80000c9e <release>
  return i;
    80004d56:	bfa9                	j	80004cb0 <pipewrite+0x54>
  int i = 0;
    80004d58:	4901                	li	s2,0
    80004d5a:	b7dd                	j	80004d40 <pipewrite+0xe4>

0000000080004d5c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d5c:	715d                	addi	sp,sp,-80
    80004d5e:	e486                	sd	ra,72(sp)
    80004d60:	e0a2                	sd	s0,64(sp)
    80004d62:	fc26                	sd	s1,56(sp)
    80004d64:	f84a                	sd	s2,48(sp)
    80004d66:	f44e                	sd	s3,40(sp)
    80004d68:	f052                	sd	s4,32(sp)
    80004d6a:	ec56                	sd	s5,24(sp)
    80004d6c:	e85a                	sd	s6,16(sp)
    80004d6e:	0880                	addi	s0,sp,80
    80004d70:	84aa                	mv	s1,a0
    80004d72:	892e                	mv	s2,a1
    80004d74:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d76:	ffffd097          	auipc	ra,0xffffd
    80004d7a:	c50080e7          	jalr	-944(ra) # 800019c6 <myproc>
    80004d7e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d80:	8b26                	mv	s6,s1
    80004d82:	8526                	mv	a0,s1
    80004d84:	ffffc097          	auipc	ra,0xffffc
    80004d88:	e66080e7          	jalr	-410(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d8c:	2184a703          	lw	a4,536(s1)
    80004d90:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d94:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d98:	02f71763          	bne	a4,a5,80004dc6 <piperead+0x6a>
    80004d9c:	2244a783          	lw	a5,548(s1)
    80004da0:	c39d                	beqz	a5,80004dc6 <piperead+0x6a>
    if(killed(pr)){
    80004da2:	8552                	mv	a0,s4
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	56e080e7          	jalr	1390(ra) # 80002312 <killed>
    80004dac:	e941                	bnez	a0,80004e3c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dae:	85da                	mv	a1,s6
    80004db0:	854e                	mv	a0,s3
    80004db2:	ffffd097          	auipc	ra,0xffffd
    80004db6:	2b8080e7          	jalr	696(ra) # 8000206a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dba:	2184a703          	lw	a4,536(s1)
    80004dbe:	21c4a783          	lw	a5,540(s1)
    80004dc2:	fcf70de3          	beq	a4,a5,80004d9c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dc6:	09505263          	blez	s5,80004e4a <piperead+0xee>
    80004dca:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dcc:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004dce:	2184a783          	lw	a5,536(s1)
    80004dd2:	21c4a703          	lw	a4,540(s1)
    80004dd6:	02f70d63          	beq	a4,a5,80004e10 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004dda:	0017871b          	addiw	a4,a5,1
    80004dde:	20e4ac23          	sw	a4,536(s1)
    80004de2:	1ff7f793          	andi	a5,a5,511
    80004de6:	97a6                	add	a5,a5,s1
    80004de8:	0187c783          	lbu	a5,24(a5)
    80004dec:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df0:	4685                	li	a3,1
    80004df2:	fbf40613          	addi	a2,s0,-65
    80004df6:	85ca                	mv	a1,s2
    80004df8:	050a3503          	ld	a0,80(s4)
    80004dfc:	ffffd097          	auipc	ra,0xffffd
    80004e00:	888080e7          	jalr	-1912(ra) # 80001684 <copyout>
    80004e04:	01650663          	beq	a0,s6,80004e10 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e08:	2985                	addiw	s3,s3,1
    80004e0a:	0905                	addi	s2,s2,1
    80004e0c:	fd3a91e3          	bne	s5,s3,80004dce <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e10:	21c48513          	addi	a0,s1,540
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	2ba080e7          	jalr	698(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004e1c:	8526                	mv	a0,s1
    80004e1e:	ffffc097          	auipc	ra,0xffffc
    80004e22:	e80080e7          	jalr	-384(ra) # 80000c9e <release>
  return i;
}
    80004e26:	854e                	mv	a0,s3
    80004e28:	60a6                	ld	ra,72(sp)
    80004e2a:	6406                	ld	s0,64(sp)
    80004e2c:	74e2                	ld	s1,56(sp)
    80004e2e:	7942                	ld	s2,48(sp)
    80004e30:	79a2                	ld	s3,40(sp)
    80004e32:	7a02                	ld	s4,32(sp)
    80004e34:	6ae2                	ld	s5,24(sp)
    80004e36:	6b42                	ld	s6,16(sp)
    80004e38:	6161                	addi	sp,sp,80
    80004e3a:	8082                	ret
      release(&pi->lock);
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	ffffc097          	auipc	ra,0xffffc
    80004e42:	e60080e7          	jalr	-416(ra) # 80000c9e <release>
      return -1;
    80004e46:	59fd                	li	s3,-1
    80004e48:	bff9                	j	80004e26 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e4a:	4981                	li	s3,0
    80004e4c:	b7d1                	j	80004e10 <piperead+0xb4>

0000000080004e4e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e4e:	1141                	addi	sp,sp,-16
    80004e50:	e422                	sd	s0,8(sp)
    80004e52:	0800                	addi	s0,sp,16
    80004e54:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e56:	8905                	andi	a0,a0,1
    80004e58:	c111                	beqz	a0,80004e5c <flags2perm+0xe>
      perm = PTE_X;
    80004e5a:	4521                	li	a0,8
    if(flags & 0x2)
    80004e5c:	8b89                	andi	a5,a5,2
    80004e5e:	c399                	beqz	a5,80004e64 <flags2perm+0x16>
      perm |= PTE_W;
    80004e60:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e64:	6422                	ld	s0,8(sp)
    80004e66:	0141                	addi	sp,sp,16
    80004e68:	8082                	ret

0000000080004e6a <exec>:

int
exec(char *path, char **argv)
{
    80004e6a:	df010113          	addi	sp,sp,-528
    80004e6e:	20113423          	sd	ra,520(sp)
    80004e72:	20813023          	sd	s0,512(sp)
    80004e76:	ffa6                	sd	s1,504(sp)
    80004e78:	fbca                	sd	s2,496(sp)
    80004e7a:	f7ce                	sd	s3,488(sp)
    80004e7c:	f3d2                	sd	s4,480(sp)
    80004e7e:	efd6                	sd	s5,472(sp)
    80004e80:	ebda                	sd	s6,464(sp)
    80004e82:	e7de                	sd	s7,456(sp)
    80004e84:	e3e2                	sd	s8,448(sp)
    80004e86:	ff66                	sd	s9,440(sp)
    80004e88:	fb6a                	sd	s10,432(sp)
    80004e8a:	f76e                	sd	s11,424(sp)
    80004e8c:	0c00                	addi	s0,sp,528
    80004e8e:	84aa                	mv	s1,a0
    80004e90:	dea43c23          	sd	a0,-520(s0)
    80004e94:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	b2e080e7          	jalr	-1234(ra) # 800019c6 <myproc>
    80004ea0:	892a                	mv	s2,a0

  begin_op();
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	474080e7          	jalr	1140(ra) # 80004316 <begin_op>

  if((ip = namei(path)) == 0){
    80004eaa:	8526                	mv	a0,s1
    80004eac:	fffff097          	auipc	ra,0xfffff
    80004eb0:	24e080e7          	jalr	590(ra) # 800040fa <namei>
    80004eb4:	c92d                	beqz	a0,80004f26 <exec+0xbc>
    80004eb6:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	a9c080e7          	jalr	-1380(ra) # 80003954 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ec0:	04000713          	li	a4,64
    80004ec4:	4681                	li	a3,0
    80004ec6:	e5040613          	addi	a2,s0,-432
    80004eca:	4581                	li	a1,0
    80004ecc:	8526                	mv	a0,s1
    80004ece:	fffff097          	auipc	ra,0xfffff
    80004ed2:	d3a080e7          	jalr	-710(ra) # 80003c08 <readi>
    80004ed6:	04000793          	li	a5,64
    80004eda:	00f51a63          	bne	a0,a5,80004eee <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004ede:	e5042703          	lw	a4,-432(s0)
    80004ee2:	464c47b7          	lui	a5,0x464c4
    80004ee6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004eea:	04f70463          	beq	a4,a5,80004f32 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004eee:	8526                	mv	a0,s1
    80004ef0:	fffff097          	auipc	ra,0xfffff
    80004ef4:	cc6080e7          	jalr	-826(ra) # 80003bb6 <iunlockput>
    end_op();
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	49e080e7          	jalr	1182(ra) # 80004396 <end_op>
  }
  return -1;
    80004f00:	557d                	li	a0,-1
}
    80004f02:	20813083          	ld	ra,520(sp)
    80004f06:	20013403          	ld	s0,512(sp)
    80004f0a:	74fe                	ld	s1,504(sp)
    80004f0c:	795e                	ld	s2,496(sp)
    80004f0e:	79be                	ld	s3,488(sp)
    80004f10:	7a1e                	ld	s4,480(sp)
    80004f12:	6afe                	ld	s5,472(sp)
    80004f14:	6b5e                	ld	s6,464(sp)
    80004f16:	6bbe                	ld	s7,456(sp)
    80004f18:	6c1e                	ld	s8,448(sp)
    80004f1a:	7cfa                	ld	s9,440(sp)
    80004f1c:	7d5a                	ld	s10,432(sp)
    80004f1e:	7dba                	ld	s11,424(sp)
    80004f20:	21010113          	addi	sp,sp,528
    80004f24:	8082                	ret
    end_op();
    80004f26:	fffff097          	auipc	ra,0xfffff
    80004f2a:	470080e7          	jalr	1136(ra) # 80004396 <end_op>
    return -1;
    80004f2e:	557d                	li	a0,-1
    80004f30:	bfc9                	j	80004f02 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f32:	854a                	mv	a0,s2
    80004f34:	ffffd097          	auipc	ra,0xffffd
    80004f38:	b56080e7          	jalr	-1194(ra) # 80001a8a <proc_pagetable>
    80004f3c:	8baa                	mv	s7,a0
    80004f3e:	d945                	beqz	a0,80004eee <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f40:	e7042983          	lw	s3,-400(s0)
    80004f44:	e8845783          	lhu	a5,-376(s0)
    80004f48:	c7ad                	beqz	a5,80004fb2 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f4a:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f4c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f4e:	6c85                	lui	s9,0x1
    80004f50:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f54:	def43823          	sd	a5,-528(s0)
    80004f58:	ac0d                	j	8000518a <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f5a:	00003517          	auipc	a0,0x3
    80004f5e:	78650513          	addi	a0,a0,1926 # 800086e0 <syscalls+0x290>
    80004f62:	ffffb097          	auipc	ra,0xffffb
    80004f66:	5e2080e7          	jalr	1506(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f6a:	8756                	mv	a4,s5
    80004f6c:	012d86bb          	addw	a3,s11,s2
    80004f70:	4581                	li	a1,0
    80004f72:	8526                	mv	a0,s1
    80004f74:	fffff097          	auipc	ra,0xfffff
    80004f78:	c94080e7          	jalr	-876(ra) # 80003c08 <readi>
    80004f7c:	2501                	sext.w	a0,a0
    80004f7e:	1aaa9a63          	bne	s5,a0,80005132 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004f82:	6785                	lui	a5,0x1
    80004f84:	0127893b          	addw	s2,a5,s2
    80004f88:	77fd                	lui	a5,0xfffff
    80004f8a:	01478a3b          	addw	s4,a5,s4
    80004f8e:	1f897563          	bgeu	s2,s8,80005178 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004f92:	02091593          	slli	a1,s2,0x20
    80004f96:	9181                	srli	a1,a1,0x20
    80004f98:	95ea                	add	a1,a1,s10
    80004f9a:	855e                	mv	a0,s7
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	0dc080e7          	jalr	220(ra) # 80001078 <walkaddr>
    80004fa4:	862a                	mv	a2,a0
    if(pa == 0)
    80004fa6:	d955                	beqz	a0,80004f5a <exec+0xf0>
      n = PGSIZE;
    80004fa8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004faa:	fd9a70e3          	bgeu	s4,s9,80004f6a <exec+0x100>
      n = sz - i;
    80004fae:	8ad2                	mv	s5,s4
    80004fb0:	bf6d                	j	80004f6a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fb2:	4a01                	li	s4,0
  iunlockput(ip);
    80004fb4:	8526                	mv	a0,s1
    80004fb6:	fffff097          	auipc	ra,0xfffff
    80004fba:	c00080e7          	jalr	-1024(ra) # 80003bb6 <iunlockput>
  end_op();
    80004fbe:	fffff097          	auipc	ra,0xfffff
    80004fc2:	3d8080e7          	jalr	984(ra) # 80004396 <end_op>
  p = myproc();
    80004fc6:	ffffd097          	auipc	ra,0xffffd
    80004fca:	a00080e7          	jalr	-1536(ra) # 800019c6 <myproc>
    80004fce:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fd0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fd4:	6785                	lui	a5,0x1
    80004fd6:	17fd                	addi	a5,a5,-1
    80004fd8:	9a3e                	add	s4,s4,a5
    80004fda:	757d                	lui	a0,0xfffff
    80004fdc:	00aa77b3          	and	a5,s4,a0
    80004fe0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fe4:	4691                	li	a3,4
    80004fe6:	6609                	lui	a2,0x2
    80004fe8:	963e                	add	a2,a2,a5
    80004fea:	85be                	mv	a1,a5
    80004fec:	855e                	mv	a0,s7
    80004fee:	ffffc097          	auipc	ra,0xffffc
    80004ff2:	43e080e7          	jalr	1086(ra) # 8000142c <uvmalloc>
    80004ff6:	8b2a                	mv	s6,a0
  ip = 0;
    80004ff8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004ffa:	12050c63          	beqz	a0,80005132 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ffe:	75f9                	lui	a1,0xffffe
    80005000:	95aa                	add	a1,a1,a0
    80005002:	855e                	mv	a0,s7
    80005004:	ffffc097          	auipc	ra,0xffffc
    80005008:	64e080e7          	jalr	1614(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    8000500c:	7c7d                	lui	s8,0xfffff
    8000500e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005010:	e0043783          	ld	a5,-512(s0)
    80005014:	6388                	ld	a0,0(a5)
    80005016:	c535                	beqz	a0,80005082 <exec+0x218>
    80005018:	e9040993          	addi	s3,s0,-368
    8000501c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005020:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005022:	ffffc097          	auipc	ra,0xffffc
    80005026:	e48080e7          	jalr	-440(ra) # 80000e6a <strlen>
    8000502a:	2505                	addiw	a0,a0,1
    8000502c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005030:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005034:	13896663          	bltu	s2,s8,80005160 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005038:	e0043d83          	ld	s11,-512(s0)
    8000503c:	000dba03          	ld	s4,0(s11)
    80005040:	8552                	mv	a0,s4
    80005042:	ffffc097          	auipc	ra,0xffffc
    80005046:	e28080e7          	jalr	-472(ra) # 80000e6a <strlen>
    8000504a:	0015069b          	addiw	a3,a0,1
    8000504e:	8652                	mv	a2,s4
    80005050:	85ca                	mv	a1,s2
    80005052:	855e                	mv	a0,s7
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	630080e7          	jalr	1584(ra) # 80001684 <copyout>
    8000505c:	10054663          	bltz	a0,80005168 <exec+0x2fe>
    ustack[argc] = sp;
    80005060:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005064:	0485                	addi	s1,s1,1
    80005066:	008d8793          	addi	a5,s11,8
    8000506a:	e0f43023          	sd	a5,-512(s0)
    8000506e:	008db503          	ld	a0,8(s11)
    80005072:	c911                	beqz	a0,80005086 <exec+0x21c>
    if(argc >= MAXARG)
    80005074:	09a1                	addi	s3,s3,8
    80005076:	fb3c96e3          	bne	s9,s3,80005022 <exec+0x1b8>
  sz = sz1;
    8000507a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507e:	4481                	li	s1,0
    80005080:	a84d                	j	80005132 <exec+0x2c8>
  sp = sz;
    80005082:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005084:	4481                	li	s1,0
  ustack[argc] = 0;
    80005086:	00349793          	slli	a5,s1,0x3
    8000508a:	f9040713          	addi	a4,s0,-112
    8000508e:	97ba                	add	a5,a5,a4
    80005090:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005094:	00148693          	addi	a3,s1,1
    80005098:	068e                	slli	a3,a3,0x3
    8000509a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000509e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050a2:	01897663          	bgeu	s2,s8,800050ae <exec+0x244>
  sz = sz1;
    800050a6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050aa:	4481                	li	s1,0
    800050ac:	a059                	j	80005132 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050ae:	e9040613          	addi	a2,s0,-368
    800050b2:	85ca                	mv	a1,s2
    800050b4:	855e                	mv	a0,s7
    800050b6:	ffffc097          	auipc	ra,0xffffc
    800050ba:	5ce080e7          	jalr	1486(ra) # 80001684 <copyout>
    800050be:	0a054963          	bltz	a0,80005170 <exec+0x306>
  p->trapframe->a1 = sp;
    800050c2:	058ab783          	ld	a5,88(s5)
    800050c6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050ca:	df843783          	ld	a5,-520(s0)
    800050ce:	0007c703          	lbu	a4,0(a5)
    800050d2:	cf11                	beqz	a4,800050ee <exec+0x284>
    800050d4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050d6:	02f00693          	li	a3,47
    800050da:	a039                	j	800050e8 <exec+0x27e>
      last = s+1;
    800050dc:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050e0:	0785                	addi	a5,a5,1
    800050e2:	fff7c703          	lbu	a4,-1(a5)
    800050e6:	c701                	beqz	a4,800050ee <exec+0x284>
    if(*s == '/')
    800050e8:	fed71ce3          	bne	a4,a3,800050e0 <exec+0x276>
    800050ec:	bfc5                	j	800050dc <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800050ee:	4641                	li	a2,16
    800050f0:	df843583          	ld	a1,-520(s0)
    800050f4:	158a8513          	addi	a0,s5,344
    800050f8:	ffffc097          	auipc	ra,0xffffc
    800050fc:	d40080e7          	jalr	-704(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005100:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005104:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005108:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000510c:	058ab783          	ld	a5,88(s5)
    80005110:	e6843703          	ld	a4,-408(s0)
    80005114:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005116:	058ab783          	ld	a5,88(s5)
    8000511a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000511e:	85ea                	mv	a1,s10
    80005120:	ffffd097          	auipc	ra,0xffffd
    80005124:	a06080e7          	jalr	-1530(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005128:	0004851b          	sext.w	a0,s1
    8000512c:	bbd9                	j	80004f02 <exec+0x98>
    8000512e:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005132:	e0843583          	ld	a1,-504(s0)
    80005136:	855e                	mv	a0,s7
    80005138:	ffffd097          	auipc	ra,0xffffd
    8000513c:	9ee080e7          	jalr	-1554(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005140:	da0497e3          	bnez	s1,80004eee <exec+0x84>
  return -1;
    80005144:	557d                	li	a0,-1
    80005146:	bb75                	j	80004f02 <exec+0x98>
    80005148:	e1443423          	sd	s4,-504(s0)
    8000514c:	b7dd                	j	80005132 <exec+0x2c8>
    8000514e:	e1443423          	sd	s4,-504(s0)
    80005152:	b7c5                	j	80005132 <exec+0x2c8>
    80005154:	e1443423          	sd	s4,-504(s0)
    80005158:	bfe9                	j	80005132 <exec+0x2c8>
    8000515a:	e1443423          	sd	s4,-504(s0)
    8000515e:	bfd1                	j	80005132 <exec+0x2c8>
  sz = sz1;
    80005160:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005164:	4481                	li	s1,0
    80005166:	b7f1                	j	80005132 <exec+0x2c8>
  sz = sz1;
    80005168:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000516c:	4481                	li	s1,0
    8000516e:	b7d1                	j	80005132 <exec+0x2c8>
  sz = sz1;
    80005170:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005174:	4481                	li	s1,0
    80005176:	bf75                	j	80005132 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005178:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000517c:	2b05                	addiw	s6,s6,1
    8000517e:	0389899b          	addiw	s3,s3,56
    80005182:	e8845783          	lhu	a5,-376(s0)
    80005186:	e2fb57e3          	bge	s6,a5,80004fb4 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000518a:	2981                	sext.w	s3,s3
    8000518c:	03800713          	li	a4,56
    80005190:	86ce                	mv	a3,s3
    80005192:	e1840613          	addi	a2,s0,-488
    80005196:	4581                	li	a1,0
    80005198:	8526                	mv	a0,s1
    8000519a:	fffff097          	auipc	ra,0xfffff
    8000519e:	a6e080e7          	jalr	-1426(ra) # 80003c08 <readi>
    800051a2:	03800793          	li	a5,56
    800051a6:	f8f514e3          	bne	a0,a5,8000512e <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800051aa:	e1842783          	lw	a5,-488(s0)
    800051ae:	4705                	li	a4,1
    800051b0:	fce796e3          	bne	a5,a4,8000517c <exec+0x312>
    if(ph.memsz < ph.filesz)
    800051b4:	e4043903          	ld	s2,-448(s0)
    800051b8:	e3843783          	ld	a5,-456(s0)
    800051bc:	f8f966e3          	bltu	s2,a5,80005148 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051c0:	e2843783          	ld	a5,-472(s0)
    800051c4:	993e                	add	s2,s2,a5
    800051c6:	f8f964e3          	bltu	s2,a5,8000514e <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800051ca:	df043703          	ld	a4,-528(s0)
    800051ce:	8ff9                	and	a5,a5,a4
    800051d0:	f3d1                	bnez	a5,80005154 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051d2:	e1c42503          	lw	a0,-484(s0)
    800051d6:	00000097          	auipc	ra,0x0
    800051da:	c78080e7          	jalr	-904(ra) # 80004e4e <flags2perm>
    800051de:	86aa                	mv	a3,a0
    800051e0:	864a                	mv	a2,s2
    800051e2:	85d2                	mv	a1,s4
    800051e4:	855e                	mv	a0,s7
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	246080e7          	jalr	582(ra) # 8000142c <uvmalloc>
    800051ee:	e0a43423          	sd	a0,-504(s0)
    800051f2:	d525                	beqz	a0,8000515a <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051f4:	e2843d03          	ld	s10,-472(s0)
    800051f8:	e2042d83          	lw	s11,-480(s0)
    800051fc:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005200:	f60c0ce3          	beqz	s8,80005178 <exec+0x30e>
    80005204:	8a62                	mv	s4,s8
    80005206:	4901                	li	s2,0
    80005208:	b369                	j	80004f92 <exec+0x128>

000000008000520a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000520a:	7179                	addi	sp,sp,-48
    8000520c:	f406                	sd	ra,40(sp)
    8000520e:	f022                	sd	s0,32(sp)
    80005210:	ec26                	sd	s1,24(sp)
    80005212:	e84a                	sd	s2,16(sp)
    80005214:	1800                	addi	s0,sp,48
    80005216:	892e                	mv	s2,a1
    80005218:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000521a:	fdc40593          	addi	a1,s0,-36
    8000521e:	ffffe097          	auipc	ra,0xffffe
    80005222:	ac4080e7          	jalr	-1340(ra) # 80002ce2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005226:	fdc42703          	lw	a4,-36(s0)
    8000522a:	47bd                	li	a5,15
    8000522c:	02e7eb63          	bltu	a5,a4,80005262 <argfd+0x58>
    80005230:	ffffc097          	auipc	ra,0xffffc
    80005234:	796080e7          	jalr	1942(ra) # 800019c6 <myproc>
    80005238:	fdc42703          	lw	a4,-36(s0)
    8000523c:	01a70793          	addi	a5,a4,26
    80005240:	078e                	slli	a5,a5,0x3
    80005242:	953e                	add	a0,a0,a5
    80005244:	611c                	ld	a5,0(a0)
    80005246:	c385                	beqz	a5,80005266 <argfd+0x5c>
    return -1;
  if(pfd)
    80005248:	00090463          	beqz	s2,80005250 <argfd+0x46>
    *pfd = fd;
    8000524c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005250:	4501                	li	a0,0
  if(pf)
    80005252:	c091                	beqz	s1,80005256 <argfd+0x4c>
    *pf = f;
    80005254:	e09c                	sd	a5,0(s1)
}
    80005256:	70a2                	ld	ra,40(sp)
    80005258:	7402                	ld	s0,32(sp)
    8000525a:	64e2                	ld	s1,24(sp)
    8000525c:	6942                	ld	s2,16(sp)
    8000525e:	6145                	addi	sp,sp,48
    80005260:	8082                	ret
    return -1;
    80005262:	557d                	li	a0,-1
    80005264:	bfcd                	j	80005256 <argfd+0x4c>
    80005266:	557d                	li	a0,-1
    80005268:	b7fd                	j	80005256 <argfd+0x4c>

000000008000526a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000526a:	1101                	addi	sp,sp,-32
    8000526c:	ec06                	sd	ra,24(sp)
    8000526e:	e822                	sd	s0,16(sp)
    80005270:	e426                	sd	s1,8(sp)
    80005272:	1000                	addi	s0,sp,32
    80005274:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	750080e7          	jalr	1872(ra) # 800019c6 <myproc>
    8000527e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005280:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd380>
    80005284:	4501                	li	a0,0
    80005286:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005288:	6398                	ld	a4,0(a5)
    8000528a:	cb19                	beqz	a4,800052a0 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000528c:	2505                	addiw	a0,a0,1
    8000528e:	07a1                	addi	a5,a5,8
    80005290:	fed51ce3          	bne	a0,a3,80005288 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005294:	557d                	li	a0,-1
}
    80005296:	60e2                	ld	ra,24(sp)
    80005298:	6442                	ld	s0,16(sp)
    8000529a:	64a2                	ld	s1,8(sp)
    8000529c:	6105                	addi	sp,sp,32
    8000529e:	8082                	ret
      p->ofile[fd] = f;
    800052a0:	01a50793          	addi	a5,a0,26
    800052a4:	078e                	slli	a5,a5,0x3
    800052a6:	963e                	add	a2,a2,a5
    800052a8:	e204                	sd	s1,0(a2)
      return fd;
    800052aa:	b7f5                	j	80005296 <fdalloc+0x2c>

00000000800052ac <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052ac:	715d                	addi	sp,sp,-80
    800052ae:	e486                	sd	ra,72(sp)
    800052b0:	e0a2                	sd	s0,64(sp)
    800052b2:	fc26                	sd	s1,56(sp)
    800052b4:	f84a                	sd	s2,48(sp)
    800052b6:	f44e                	sd	s3,40(sp)
    800052b8:	f052                	sd	s4,32(sp)
    800052ba:	ec56                	sd	s5,24(sp)
    800052bc:	e85a                	sd	s6,16(sp)
    800052be:	0880                	addi	s0,sp,80
    800052c0:	8b2e                	mv	s6,a1
    800052c2:	89b2                	mv	s3,a2
    800052c4:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052c6:	fb040593          	addi	a1,s0,-80
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	e4e080e7          	jalr	-434(ra) # 80004118 <nameiparent>
    800052d2:	84aa                	mv	s1,a0
    800052d4:	16050063          	beqz	a0,80005434 <create+0x188>
    return 0;

  ilock(dp);
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	67c080e7          	jalr	1660(ra) # 80003954 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052e0:	4601                	li	a2,0
    800052e2:	fb040593          	addi	a1,s0,-80
    800052e6:	8526                	mv	a0,s1
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	b50080e7          	jalr	-1200(ra) # 80003e38 <dirlookup>
    800052f0:	8aaa                	mv	s5,a0
    800052f2:	c931                	beqz	a0,80005346 <create+0x9a>
    iunlockput(dp);
    800052f4:	8526                	mv	a0,s1
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	8c0080e7          	jalr	-1856(ra) # 80003bb6 <iunlockput>
    ilock(ip);
    800052fe:	8556                	mv	a0,s5
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	654080e7          	jalr	1620(ra) # 80003954 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005308:	000b059b          	sext.w	a1,s6
    8000530c:	4789                	li	a5,2
    8000530e:	02f59563          	bne	a1,a5,80005338 <create+0x8c>
    80005312:	044ad783          	lhu	a5,68(s5)
    80005316:	37f9                	addiw	a5,a5,-2
    80005318:	17c2                	slli	a5,a5,0x30
    8000531a:	93c1                	srli	a5,a5,0x30
    8000531c:	4705                	li	a4,1
    8000531e:	00f76d63          	bltu	a4,a5,80005338 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005322:	8556                	mv	a0,s5
    80005324:	60a6                	ld	ra,72(sp)
    80005326:	6406                	ld	s0,64(sp)
    80005328:	74e2                	ld	s1,56(sp)
    8000532a:	7942                	ld	s2,48(sp)
    8000532c:	79a2                	ld	s3,40(sp)
    8000532e:	7a02                	ld	s4,32(sp)
    80005330:	6ae2                	ld	s5,24(sp)
    80005332:	6b42                	ld	s6,16(sp)
    80005334:	6161                	addi	sp,sp,80
    80005336:	8082                	ret
    iunlockput(ip);
    80005338:	8556                	mv	a0,s5
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	87c080e7          	jalr	-1924(ra) # 80003bb6 <iunlockput>
    return 0;
    80005342:	4a81                	li	s5,0
    80005344:	bff9                	j	80005322 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005346:	85da                	mv	a1,s6
    80005348:	4088                	lw	a0,0(s1)
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	46e080e7          	jalr	1134(ra) # 800037b8 <ialloc>
    80005352:	8a2a                	mv	s4,a0
    80005354:	c921                	beqz	a0,800053a4 <create+0xf8>
  ilock(ip);
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	5fe080e7          	jalr	1534(ra) # 80003954 <ilock>
  ip->major = major;
    8000535e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005362:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005366:	4785                	li	a5,1
    80005368:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    8000536c:	8552                	mv	a0,s4
    8000536e:	ffffe097          	auipc	ra,0xffffe
    80005372:	51c080e7          	jalr	1308(ra) # 8000388a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005376:	000b059b          	sext.w	a1,s6
    8000537a:	4785                	li	a5,1
    8000537c:	02f58b63          	beq	a1,a5,800053b2 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005380:	004a2603          	lw	a2,4(s4)
    80005384:	fb040593          	addi	a1,s0,-80
    80005388:	8526                	mv	a0,s1
    8000538a:	fffff097          	auipc	ra,0xfffff
    8000538e:	cbe080e7          	jalr	-834(ra) # 80004048 <dirlink>
    80005392:	06054f63          	bltz	a0,80005410 <create+0x164>
  iunlockput(dp);
    80005396:	8526                	mv	a0,s1
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	81e080e7          	jalr	-2018(ra) # 80003bb6 <iunlockput>
  return ip;
    800053a0:	8ad2                	mv	s5,s4
    800053a2:	b741                	j	80005322 <create+0x76>
    iunlockput(dp);
    800053a4:	8526                	mv	a0,s1
    800053a6:	fffff097          	auipc	ra,0xfffff
    800053aa:	810080e7          	jalr	-2032(ra) # 80003bb6 <iunlockput>
    return 0;
    800053ae:	8ad2                	mv	s5,s4
    800053b0:	bf8d                	j	80005322 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053b2:	004a2603          	lw	a2,4(s4)
    800053b6:	00003597          	auipc	a1,0x3
    800053ba:	34a58593          	addi	a1,a1,842 # 80008700 <syscalls+0x2b0>
    800053be:	8552                	mv	a0,s4
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	c88080e7          	jalr	-888(ra) # 80004048 <dirlink>
    800053c8:	04054463          	bltz	a0,80005410 <create+0x164>
    800053cc:	40d0                	lw	a2,4(s1)
    800053ce:	00003597          	auipc	a1,0x3
    800053d2:	33a58593          	addi	a1,a1,826 # 80008708 <syscalls+0x2b8>
    800053d6:	8552                	mv	a0,s4
    800053d8:	fffff097          	auipc	ra,0xfffff
    800053dc:	c70080e7          	jalr	-912(ra) # 80004048 <dirlink>
    800053e0:	02054863          	bltz	a0,80005410 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800053e4:	004a2603          	lw	a2,4(s4)
    800053e8:	fb040593          	addi	a1,s0,-80
    800053ec:	8526                	mv	a0,s1
    800053ee:	fffff097          	auipc	ra,0xfffff
    800053f2:	c5a080e7          	jalr	-934(ra) # 80004048 <dirlink>
    800053f6:	00054d63          	bltz	a0,80005410 <create+0x164>
    dp->nlink++;  // for ".."
    800053fa:	04a4d783          	lhu	a5,74(s1)
    800053fe:	2785                	addiw	a5,a5,1
    80005400:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005404:	8526                	mv	a0,s1
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	484080e7          	jalr	1156(ra) # 8000388a <iupdate>
    8000540e:	b761                	j	80005396 <create+0xea>
  ip->nlink = 0;
    80005410:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005414:	8552                	mv	a0,s4
    80005416:	ffffe097          	auipc	ra,0xffffe
    8000541a:	474080e7          	jalr	1140(ra) # 8000388a <iupdate>
  iunlockput(ip);
    8000541e:	8552                	mv	a0,s4
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	796080e7          	jalr	1942(ra) # 80003bb6 <iunlockput>
  iunlockput(dp);
    80005428:	8526                	mv	a0,s1
    8000542a:	ffffe097          	auipc	ra,0xffffe
    8000542e:	78c080e7          	jalr	1932(ra) # 80003bb6 <iunlockput>
  return 0;
    80005432:	bdc5                	j	80005322 <create+0x76>
    return 0;
    80005434:	8aaa                	mv	s5,a0
    80005436:	b5f5                	j	80005322 <create+0x76>

0000000080005438 <sys_dup>:
{
    80005438:	7179                	addi	sp,sp,-48
    8000543a:	f406                	sd	ra,40(sp)
    8000543c:	f022                	sd	s0,32(sp)
    8000543e:	ec26                	sd	s1,24(sp)
    80005440:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005442:	fd840613          	addi	a2,s0,-40
    80005446:	4581                	li	a1,0
    80005448:	4501                	li	a0,0
    8000544a:	00000097          	auipc	ra,0x0
    8000544e:	dc0080e7          	jalr	-576(ra) # 8000520a <argfd>
    return -1;
    80005452:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005454:	02054363          	bltz	a0,8000547a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005458:	fd843503          	ld	a0,-40(s0)
    8000545c:	00000097          	auipc	ra,0x0
    80005460:	e0e080e7          	jalr	-498(ra) # 8000526a <fdalloc>
    80005464:	84aa                	mv	s1,a0
    return -1;
    80005466:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005468:	00054963          	bltz	a0,8000547a <sys_dup+0x42>
  filedup(f);
    8000546c:	fd843503          	ld	a0,-40(s0)
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	320080e7          	jalr	800(ra) # 80004790 <filedup>
  return fd;
    80005478:	87a6                	mv	a5,s1
}
    8000547a:	853e                	mv	a0,a5
    8000547c:	70a2                	ld	ra,40(sp)
    8000547e:	7402                	ld	s0,32(sp)
    80005480:	64e2                	ld	s1,24(sp)
    80005482:	6145                	addi	sp,sp,48
    80005484:	8082                	ret

0000000080005486 <sys_read>:
{
    80005486:	7179                	addi	sp,sp,-48
    80005488:	f406                	sd	ra,40(sp)
    8000548a:	f022                	sd	s0,32(sp)
    8000548c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000548e:	fd840593          	addi	a1,s0,-40
    80005492:	4505                	li	a0,1
    80005494:	ffffe097          	auipc	ra,0xffffe
    80005498:	86e080e7          	jalr	-1938(ra) # 80002d02 <argaddr>
  argint(2, &n);
    8000549c:	fe440593          	addi	a1,s0,-28
    800054a0:	4509                	li	a0,2
    800054a2:	ffffe097          	auipc	ra,0xffffe
    800054a6:	840080e7          	jalr	-1984(ra) # 80002ce2 <argint>
  if(argfd(0, 0, &f) < 0)
    800054aa:	fe840613          	addi	a2,s0,-24
    800054ae:	4581                	li	a1,0
    800054b0:	4501                	li	a0,0
    800054b2:	00000097          	auipc	ra,0x0
    800054b6:	d58080e7          	jalr	-680(ra) # 8000520a <argfd>
    800054ba:	87aa                	mv	a5,a0
    return -1;
    800054bc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054be:	0007cc63          	bltz	a5,800054d6 <sys_read+0x50>
  return fileread(f, p, n);
    800054c2:	fe442603          	lw	a2,-28(s0)
    800054c6:	fd843583          	ld	a1,-40(s0)
    800054ca:	fe843503          	ld	a0,-24(s0)
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	44e080e7          	jalr	1102(ra) # 8000491c <fileread>
}
    800054d6:	70a2                	ld	ra,40(sp)
    800054d8:	7402                	ld	s0,32(sp)
    800054da:	6145                	addi	sp,sp,48
    800054dc:	8082                	ret

00000000800054de <sys_write>:
{
    800054de:	7179                	addi	sp,sp,-48
    800054e0:	f406                	sd	ra,40(sp)
    800054e2:	f022                	sd	s0,32(sp)
    800054e4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054e6:	fd840593          	addi	a1,s0,-40
    800054ea:	4505                	li	a0,1
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	816080e7          	jalr	-2026(ra) # 80002d02 <argaddr>
  argint(2, &n);
    800054f4:	fe440593          	addi	a1,s0,-28
    800054f8:	4509                	li	a0,2
    800054fa:	ffffd097          	auipc	ra,0xffffd
    800054fe:	7e8080e7          	jalr	2024(ra) # 80002ce2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005502:	fe840613          	addi	a2,s0,-24
    80005506:	4581                	li	a1,0
    80005508:	4501                	li	a0,0
    8000550a:	00000097          	auipc	ra,0x0
    8000550e:	d00080e7          	jalr	-768(ra) # 8000520a <argfd>
    80005512:	87aa                	mv	a5,a0
    return -1;
    80005514:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005516:	0007cc63          	bltz	a5,8000552e <sys_write+0x50>
  return filewrite(f, p, n);
    8000551a:	fe442603          	lw	a2,-28(s0)
    8000551e:	fd843583          	ld	a1,-40(s0)
    80005522:	fe843503          	ld	a0,-24(s0)
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	4b8080e7          	jalr	1208(ra) # 800049de <filewrite>
}
    8000552e:	70a2                	ld	ra,40(sp)
    80005530:	7402                	ld	s0,32(sp)
    80005532:	6145                	addi	sp,sp,48
    80005534:	8082                	ret

0000000080005536 <sys_close>:
{
    80005536:	1101                	addi	sp,sp,-32
    80005538:	ec06                	sd	ra,24(sp)
    8000553a:	e822                	sd	s0,16(sp)
    8000553c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000553e:	fe040613          	addi	a2,s0,-32
    80005542:	fec40593          	addi	a1,s0,-20
    80005546:	4501                	li	a0,0
    80005548:	00000097          	auipc	ra,0x0
    8000554c:	cc2080e7          	jalr	-830(ra) # 8000520a <argfd>
    return -1;
    80005550:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005552:	02054463          	bltz	a0,8000557a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005556:	ffffc097          	auipc	ra,0xffffc
    8000555a:	470080e7          	jalr	1136(ra) # 800019c6 <myproc>
    8000555e:	fec42783          	lw	a5,-20(s0)
    80005562:	07e9                	addi	a5,a5,26
    80005564:	078e                	slli	a5,a5,0x3
    80005566:	97aa                	add	a5,a5,a0
    80005568:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000556c:	fe043503          	ld	a0,-32(s0)
    80005570:	fffff097          	auipc	ra,0xfffff
    80005574:	272080e7          	jalr	626(ra) # 800047e2 <fileclose>
  return 0;
    80005578:	4781                	li	a5,0
}
    8000557a:	853e                	mv	a0,a5
    8000557c:	60e2                	ld	ra,24(sp)
    8000557e:	6442                	ld	s0,16(sp)
    80005580:	6105                	addi	sp,sp,32
    80005582:	8082                	ret

0000000080005584 <sys_fstat>:
{
    80005584:	1101                	addi	sp,sp,-32
    80005586:	ec06                	sd	ra,24(sp)
    80005588:	e822                	sd	s0,16(sp)
    8000558a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000558c:	fe040593          	addi	a1,s0,-32
    80005590:	4505                	li	a0,1
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	770080e7          	jalr	1904(ra) # 80002d02 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000559a:	fe840613          	addi	a2,s0,-24
    8000559e:	4581                	li	a1,0
    800055a0:	4501                	li	a0,0
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	c68080e7          	jalr	-920(ra) # 8000520a <argfd>
    800055aa:	87aa                	mv	a5,a0
    return -1;
    800055ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ae:	0007ca63          	bltz	a5,800055c2 <sys_fstat+0x3e>
  return filestat(f, st);
    800055b2:	fe043583          	ld	a1,-32(s0)
    800055b6:	fe843503          	ld	a0,-24(s0)
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	2f0080e7          	jalr	752(ra) # 800048aa <filestat>
}
    800055c2:	60e2                	ld	ra,24(sp)
    800055c4:	6442                	ld	s0,16(sp)
    800055c6:	6105                	addi	sp,sp,32
    800055c8:	8082                	ret

00000000800055ca <sys_link>:
{
    800055ca:	7169                	addi	sp,sp,-304
    800055cc:	f606                	sd	ra,296(sp)
    800055ce:	f222                	sd	s0,288(sp)
    800055d0:	ee26                	sd	s1,280(sp)
    800055d2:	ea4a                	sd	s2,272(sp)
    800055d4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d6:	08000613          	li	a2,128
    800055da:	ed040593          	addi	a1,s0,-304
    800055de:	4501                	li	a0,0
    800055e0:	ffffd097          	auipc	ra,0xffffd
    800055e4:	742080e7          	jalr	1858(ra) # 80002d22 <argstr>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ea:	10054e63          	bltz	a0,80005706 <sys_link+0x13c>
    800055ee:	08000613          	li	a2,128
    800055f2:	f5040593          	addi	a1,s0,-176
    800055f6:	4505                	li	a0,1
    800055f8:	ffffd097          	auipc	ra,0xffffd
    800055fc:	72a080e7          	jalr	1834(ra) # 80002d22 <argstr>
    return -1;
    80005600:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005602:	10054263          	bltz	a0,80005706 <sys_link+0x13c>
  begin_op();
    80005606:	fffff097          	auipc	ra,0xfffff
    8000560a:	d10080e7          	jalr	-752(ra) # 80004316 <begin_op>
  if((ip = namei(old)) == 0){
    8000560e:	ed040513          	addi	a0,s0,-304
    80005612:	fffff097          	auipc	ra,0xfffff
    80005616:	ae8080e7          	jalr	-1304(ra) # 800040fa <namei>
    8000561a:	84aa                	mv	s1,a0
    8000561c:	c551                	beqz	a0,800056a8 <sys_link+0xde>
  ilock(ip);
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	336080e7          	jalr	822(ra) # 80003954 <ilock>
  if(ip->type == T_DIR){
    80005626:	04449703          	lh	a4,68(s1)
    8000562a:	4785                	li	a5,1
    8000562c:	08f70463          	beq	a4,a5,800056b4 <sys_link+0xea>
  ip->nlink++;
    80005630:	04a4d783          	lhu	a5,74(s1)
    80005634:	2785                	addiw	a5,a5,1
    80005636:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	24e080e7          	jalr	590(ra) # 8000388a <iupdate>
  iunlock(ip);
    80005644:	8526                	mv	a0,s1
    80005646:	ffffe097          	auipc	ra,0xffffe
    8000564a:	3d0080e7          	jalr	976(ra) # 80003a16 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000564e:	fd040593          	addi	a1,s0,-48
    80005652:	f5040513          	addi	a0,s0,-176
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	ac2080e7          	jalr	-1342(ra) # 80004118 <nameiparent>
    8000565e:	892a                	mv	s2,a0
    80005660:	c935                	beqz	a0,800056d4 <sys_link+0x10a>
  ilock(dp);
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	2f2080e7          	jalr	754(ra) # 80003954 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000566a:	00092703          	lw	a4,0(s2)
    8000566e:	409c                	lw	a5,0(s1)
    80005670:	04f71d63          	bne	a4,a5,800056ca <sys_link+0x100>
    80005674:	40d0                	lw	a2,4(s1)
    80005676:	fd040593          	addi	a1,s0,-48
    8000567a:	854a                	mv	a0,s2
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	9cc080e7          	jalr	-1588(ra) # 80004048 <dirlink>
    80005684:	04054363          	bltz	a0,800056ca <sys_link+0x100>
  iunlockput(dp);
    80005688:	854a                	mv	a0,s2
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	52c080e7          	jalr	1324(ra) # 80003bb6 <iunlockput>
  iput(ip);
    80005692:	8526                	mv	a0,s1
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	47a080e7          	jalr	1146(ra) # 80003b0e <iput>
  end_op();
    8000569c:	fffff097          	auipc	ra,0xfffff
    800056a0:	cfa080e7          	jalr	-774(ra) # 80004396 <end_op>
  return 0;
    800056a4:	4781                	li	a5,0
    800056a6:	a085                	j	80005706 <sys_link+0x13c>
    end_op();
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	cee080e7          	jalr	-786(ra) # 80004396 <end_op>
    return -1;
    800056b0:	57fd                	li	a5,-1
    800056b2:	a891                	j	80005706 <sys_link+0x13c>
    iunlockput(ip);
    800056b4:	8526                	mv	a0,s1
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	500080e7          	jalr	1280(ra) # 80003bb6 <iunlockput>
    end_op();
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	cd8080e7          	jalr	-808(ra) # 80004396 <end_op>
    return -1;
    800056c6:	57fd                	li	a5,-1
    800056c8:	a83d                	j	80005706 <sys_link+0x13c>
    iunlockput(dp);
    800056ca:	854a                	mv	a0,s2
    800056cc:	ffffe097          	auipc	ra,0xffffe
    800056d0:	4ea080e7          	jalr	1258(ra) # 80003bb6 <iunlockput>
  ilock(ip);
    800056d4:	8526                	mv	a0,s1
    800056d6:	ffffe097          	auipc	ra,0xffffe
    800056da:	27e080e7          	jalr	638(ra) # 80003954 <ilock>
  ip->nlink--;
    800056de:	04a4d783          	lhu	a5,74(s1)
    800056e2:	37fd                	addiw	a5,a5,-1
    800056e4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056e8:	8526                	mv	a0,s1
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	1a0080e7          	jalr	416(ra) # 8000388a <iupdate>
  iunlockput(ip);
    800056f2:	8526                	mv	a0,s1
    800056f4:	ffffe097          	auipc	ra,0xffffe
    800056f8:	4c2080e7          	jalr	1218(ra) # 80003bb6 <iunlockput>
  end_op();
    800056fc:	fffff097          	auipc	ra,0xfffff
    80005700:	c9a080e7          	jalr	-870(ra) # 80004396 <end_op>
  return -1;
    80005704:	57fd                	li	a5,-1
}
    80005706:	853e                	mv	a0,a5
    80005708:	70b2                	ld	ra,296(sp)
    8000570a:	7412                	ld	s0,288(sp)
    8000570c:	64f2                	ld	s1,280(sp)
    8000570e:	6952                	ld	s2,272(sp)
    80005710:	6155                	addi	sp,sp,304
    80005712:	8082                	ret

0000000080005714 <sys_unlink>:
{
    80005714:	7151                	addi	sp,sp,-240
    80005716:	f586                	sd	ra,232(sp)
    80005718:	f1a2                	sd	s0,224(sp)
    8000571a:	eda6                	sd	s1,216(sp)
    8000571c:	e9ca                	sd	s2,208(sp)
    8000571e:	e5ce                	sd	s3,200(sp)
    80005720:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005722:	08000613          	li	a2,128
    80005726:	f3040593          	addi	a1,s0,-208
    8000572a:	4501                	li	a0,0
    8000572c:	ffffd097          	auipc	ra,0xffffd
    80005730:	5f6080e7          	jalr	1526(ra) # 80002d22 <argstr>
    80005734:	18054163          	bltz	a0,800058b6 <sys_unlink+0x1a2>
  begin_op();
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	bde080e7          	jalr	-1058(ra) # 80004316 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005740:	fb040593          	addi	a1,s0,-80
    80005744:	f3040513          	addi	a0,s0,-208
    80005748:	fffff097          	auipc	ra,0xfffff
    8000574c:	9d0080e7          	jalr	-1584(ra) # 80004118 <nameiparent>
    80005750:	84aa                	mv	s1,a0
    80005752:	c979                	beqz	a0,80005828 <sys_unlink+0x114>
  ilock(dp);
    80005754:	ffffe097          	auipc	ra,0xffffe
    80005758:	200080e7          	jalr	512(ra) # 80003954 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000575c:	00003597          	auipc	a1,0x3
    80005760:	fa458593          	addi	a1,a1,-92 # 80008700 <syscalls+0x2b0>
    80005764:	fb040513          	addi	a0,s0,-80
    80005768:	ffffe097          	auipc	ra,0xffffe
    8000576c:	6b6080e7          	jalr	1718(ra) # 80003e1e <namecmp>
    80005770:	14050a63          	beqz	a0,800058c4 <sys_unlink+0x1b0>
    80005774:	00003597          	auipc	a1,0x3
    80005778:	f9458593          	addi	a1,a1,-108 # 80008708 <syscalls+0x2b8>
    8000577c:	fb040513          	addi	a0,s0,-80
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	69e080e7          	jalr	1694(ra) # 80003e1e <namecmp>
    80005788:	12050e63          	beqz	a0,800058c4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000578c:	f2c40613          	addi	a2,s0,-212
    80005790:	fb040593          	addi	a1,s0,-80
    80005794:	8526                	mv	a0,s1
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	6a2080e7          	jalr	1698(ra) # 80003e38 <dirlookup>
    8000579e:	892a                	mv	s2,a0
    800057a0:	12050263          	beqz	a0,800058c4 <sys_unlink+0x1b0>
  ilock(ip);
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	1b0080e7          	jalr	432(ra) # 80003954 <ilock>
  if(ip->nlink < 1)
    800057ac:	04a91783          	lh	a5,74(s2)
    800057b0:	08f05263          	blez	a5,80005834 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057b4:	04491703          	lh	a4,68(s2)
    800057b8:	4785                	li	a5,1
    800057ba:	08f70563          	beq	a4,a5,80005844 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057be:	4641                	li	a2,16
    800057c0:	4581                	li	a1,0
    800057c2:	fc040513          	addi	a0,s0,-64
    800057c6:	ffffb097          	auipc	ra,0xffffb
    800057ca:	520080e7          	jalr	1312(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057ce:	4741                	li	a4,16
    800057d0:	f2c42683          	lw	a3,-212(s0)
    800057d4:	fc040613          	addi	a2,s0,-64
    800057d8:	4581                	li	a1,0
    800057da:	8526                	mv	a0,s1
    800057dc:	ffffe097          	auipc	ra,0xffffe
    800057e0:	524080e7          	jalr	1316(ra) # 80003d00 <writei>
    800057e4:	47c1                	li	a5,16
    800057e6:	0af51563          	bne	a0,a5,80005890 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057ea:	04491703          	lh	a4,68(s2)
    800057ee:	4785                	li	a5,1
    800057f0:	0af70863          	beq	a4,a5,800058a0 <sys_unlink+0x18c>
  iunlockput(dp);
    800057f4:	8526                	mv	a0,s1
    800057f6:	ffffe097          	auipc	ra,0xffffe
    800057fa:	3c0080e7          	jalr	960(ra) # 80003bb6 <iunlockput>
  ip->nlink--;
    800057fe:	04a95783          	lhu	a5,74(s2)
    80005802:	37fd                	addiw	a5,a5,-1
    80005804:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005808:	854a                	mv	a0,s2
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	080080e7          	jalr	128(ra) # 8000388a <iupdate>
  iunlockput(ip);
    80005812:	854a                	mv	a0,s2
    80005814:	ffffe097          	auipc	ra,0xffffe
    80005818:	3a2080e7          	jalr	930(ra) # 80003bb6 <iunlockput>
  end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	b7a080e7          	jalr	-1158(ra) # 80004396 <end_op>
  return 0;
    80005824:	4501                	li	a0,0
    80005826:	a84d                	j	800058d8 <sys_unlink+0x1c4>
    end_op();
    80005828:	fffff097          	auipc	ra,0xfffff
    8000582c:	b6e080e7          	jalr	-1170(ra) # 80004396 <end_op>
    return -1;
    80005830:	557d                	li	a0,-1
    80005832:	a05d                	j	800058d8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005834:	00003517          	auipc	a0,0x3
    80005838:	edc50513          	addi	a0,a0,-292 # 80008710 <syscalls+0x2c0>
    8000583c:	ffffb097          	auipc	ra,0xffffb
    80005840:	d08080e7          	jalr	-760(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005844:	04c92703          	lw	a4,76(s2)
    80005848:	02000793          	li	a5,32
    8000584c:	f6e7f9e3          	bgeu	a5,a4,800057be <sys_unlink+0xaa>
    80005850:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005854:	4741                	li	a4,16
    80005856:	86ce                	mv	a3,s3
    80005858:	f1840613          	addi	a2,s0,-232
    8000585c:	4581                	li	a1,0
    8000585e:	854a                	mv	a0,s2
    80005860:	ffffe097          	auipc	ra,0xffffe
    80005864:	3a8080e7          	jalr	936(ra) # 80003c08 <readi>
    80005868:	47c1                	li	a5,16
    8000586a:	00f51b63          	bne	a0,a5,80005880 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000586e:	f1845783          	lhu	a5,-232(s0)
    80005872:	e7a1                	bnez	a5,800058ba <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005874:	29c1                	addiw	s3,s3,16
    80005876:	04c92783          	lw	a5,76(s2)
    8000587a:	fcf9ede3          	bltu	s3,a5,80005854 <sys_unlink+0x140>
    8000587e:	b781                	j	800057be <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005880:	00003517          	auipc	a0,0x3
    80005884:	ea850513          	addi	a0,a0,-344 # 80008728 <syscalls+0x2d8>
    80005888:	ffffb097          	auipc	ra,0xffffb
    8000588c:	cbc080e7          	jalr	-836(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005890:	00003517          	auipc	a0,0x3
    80005894:	eb050513          	addi	a0,a0,-336 # 80008740 <syscalls+0x2f0>
    80005898:	ffffb097          	auipc	ra,0xffffb
    8000589c:	cac080e7          	jalr	-852(ra) # 80000544 <panic>
    dp->nlink--;
    800058a0:	04a4d783          	lhu	a5,74(s1)
    800058a4:	37fd                	addiw	a5,a5,-1
    800058a6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058aa:	8526                	mv	a0,s1
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	fde080e7          	jalr	-34(ra) # 8000388a <iupdate>
    800058b4:	b781                	j	800057f4 <sys_unlink+0xe0>
    return -1;
    800058b6:	557d                	li	a0,-1
    800058b8:	a005                	j	800058d8 <sys_unlink+0x1c4>
    iunlockput(ip);
    800058ba:	854a                	mv	a0,s2
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	2fa080e7          	jalr	762(ra) # 80003bb6 <iunlockput>
  iunlockput(dp);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	2f0080e7          	jalr	752(ra) # 80003bb6 <iunlockput>
  end_op();
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	ac8080e7          	jalr	-1336(ra) # 80004396 <end_op>
  return -1;
    800058d6:	557d                	li	a0,-1
}
    800058d8:	70ae                	ld	ra,232(sp)
    800058da:	740e                	ld	s0,224(sp)
    800058dc:	64ee                	ld	s1,216(sp)
    800058de:	694e                	ld	s2,208(sp)
    800058e0:	69ae                	ld	s3,200(sp)
    800058e2:	616d                	addi	sp,sp,240
    800058e4:	8082                	ret

00000000800058e6 <sys_open>:

uint64
sys_open(void)
{
    800058e6:	7131                	addi	sp,sp,-192
    800058e8:	fd06                	sd	ra,184(sp)
    800058ea:	f922                	sd	s0,176(sp)
    800058ec:	f526                	sd	s1,168(sp)
    800058ee:	f14a                	sd	s2,160(sp)
    800058f0:	ed4e                	sd	s3,152(sp)
    800058f2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058f4:	f4c40593          	addi	a1,s0,-180
    800058f8:	4505                	li	a0,1
    800058fa:	ffffd097          	auipc	ra,0xffffd
    800058fe:	3e8080e7          	jalr	1000(ra) # 80002ce2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005902:	08000613          	li	a2,128
    80005906:	f5040593          	addi	a1,s0,-176
    8000590a:	4501                	li	a0,0
    8000590c:	ffffd097          	auipc	ra,0xffffd
    80005910:	416080e7          	jalr	1046(ra) # 80002d22 <argstr>
    80005914:	87aa                	mv	a5,a0
    return -1;
    80005916:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005918:	0a07c963          	bltz	a5,800059ca <sys_open+0xe4>

  begin_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	9fa080e7          	jalr	-1542(ra) # 80004316 <begin_op>

  if(omode & O_CREATE){
    80005924:	f4c42783          	lw	a5,-180(s0)
    80005928:	2007f793          	andi	a5,a5,512
    8000592c:	cfc5                	beqz	a5,800059e4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000592e:	4681                	li	a3,0
    80005930:	4601                	li	a2,0
    80005932:	4589                	li	a1,2
    80005934:	f5040513          	addi	a0,s0,-176
    80005938:	00000097          	auipc	ra,0x0
    8000593c:	974080e7          	jalr	-1676(ra) # 800052ac <create>
    80005940:	84aa                	mv	s1,a0
    if(ip == 0){
    80005942:	c959                	beqz	a0,800059d8 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005944:	04449703          	lh	a4,68(s1)
    80005948:	478d                	li	a5,3
    8000594a:	00f71763          	bne	a4,a5,80005958 <sys_open+0x72>
    8000594e:	0464d703          	lhu	a4,70(s1)
    80005952:	47a5                	li	a5,9
    80005954:	0ce7ed63          	bltu	a5,a4,80005a2e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	dce080e7          	jalr	-562(ra) # 80004726 <filealloc>
    80005960:	89aa                	mv	s3,a0
    80005962:	10050363          	beqz	a0,80005a68 <sys_open+0x182>
    80005966:	00000097          	auipc	ra,0x0
    8000596a:	904080e7          	jalr	-1788(ra) # 8000526a <fdalloc>
    8000596e:	892a                	mv	s2,a0
    80005970:	0e054763          	bltz	a0,80005a5e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005974:	04449703          	lh	a4,68(s1)
    80005978:	478d                	li	a5,3
    8000597a:	0cf70563          	beq	a4,a5,80005a44 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000597e:	4789                	li	a5,2
    80005980:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005984:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005988:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000598c:	f4c42783          	lw	a5,-180(s0)
    80005990:	0017c713          	xori	a4,a5,1
    80005994:	8b05                	andi	a4,a4,1
    80005996:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000599a:	0037f713          	andi	a4,a5,3
    8000599e:	00e03733          	snez	a4,a4
    800059a2:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059a6:	4007f793          	andi	a5,a5,1024
    800059aa:	c791                	beqz	a5,800059b6 <sys_open+0xd0>
    800059ac:	04449703          	lh	a4,68(s1)
    800059b0:	4789                	li	a5,2
    800059b2:	0af70063          	beq	a4,a5,80005a52 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059b6:	8526                	mv	a0,s1
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	05e080e7          	jalr	94(ra) # 80003a16 <iunlock>
  end_op();
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	9d6080e7          	jalr	-1578(ra) # 80004396 <end_op>

  return fd;
    800059c8:	854a                	mv	a0,s2
}
    800059ca:	70ea                	ld	ra,184(sp)
    800059cc:	744a                	ld	s0,176(sp)
    800059ce:	74aa                	ld	s1,168(sp)
    800059d0:	790a                	ld	s2,160(sp)
    800059d2:	69ea                	ld	s3,152(sp)
    800059d4:	6129                	addi	sp,sp,192
    800059d6:	8082                	ret
      end_op();
    800059d8:	fffff097          	auipc	ra,0xfffff
    800059dc:	9be080e7          	jalr	-1602(ra) # 80004396 <end_op>
      return -1;
    800059e0:	557d                	li	a0,-1
    800059e2:	b7e5                	j	800059ca <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059e4:	f5040513          	addi	a0,s0,-176
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	712080e7          	jalr	1810(ra) # 800040fa <namei>
    800059f0:	84aa                	mv	s1,a0
    800059f2:	c905                	beqz	a0,80005a22 <sys_open+0x13c>
    ilock(ip);
    800059f4:	ffffe097          	auipc	ra,0xffffe
    800059f8:	f60080e7          	jalr	-160(ra) # 80003954 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059fc:	04449703          	lh	a4,68(s1)
    80005a00:	4785                	li	a5,1
    80005a02:	f4f711e3          	bne	a4,a5,80005944 <sys_open+0x5e>
    80005a06:	f4c42783          	lw	a5,-180(s0)
    80005a0a:	d7b9                	beqz	a5,80005958 <sys_open+0x72>
      iunlockput(ip);
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	1a8080e7          	jalr	424(ra) # 80003bb6 <iunlockput>
      end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	980080e7          	jalr	-1664(ra) # 80004396 <end_op>
      return -1;
    80005a1e:	557d                	li	a0,-1
    80005a20:	b76d                	j	800059ca <sys_open+0xe4>
      end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	974080e7          	jalr	-1676(ra) # 80004396 <end_op>
      return -1;
    80005a2a:	557d                	li	a0,-1
    80005a2c:	bf79                	j	800059ca <sys_open+0xe4>
    iunlockput(ip);
    80005a2e:	8526                	mv	a0,s1
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	186080e7          	jalr	390(ra) # 80003bb6 <iunlockput>
    end_op();
    80005a38:	fffff097          	auipc	ra,0xfffff
    80005a3c:	95e080e7          	jalr	-1698(ra) # 80004396 <end_op>
    return -1;
    80005a40:	557d                	li	a0,-1
    80005a42:	b761                	j	800059ca <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a44:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a48:	04649783          	lh	a5,70(s1)
    80005a4c:	02f99223          	sh	a5,36(s3)
    80005a50:	bf25                	j	80005988 <sys_open+0xa2>
    itrunc(ip);
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	00e080e7          	jalr	14(ra) # 80003a62 <itrunc>
    80005a5c:	bfa9                	j	800059b6 <sys_open+0xd0>
      fileclose(f);
    80005a5e:	854e                	mv	a0,s3
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	d82080e7          	jalr	-638(ra) # 800047e2 <fileclose>
    iunlockput(ip);
    80005a68:	8526                	mv	a0,s1
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	14c080e7          	jalr	332(ra) # 80003bb6 <iunlockput>
    end_op();
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	924080e7          	jalr	-1756(ra) # 80004396 <end_op>
    return -1;
    80005a7a:	557d                	li	a0,-1
    80005a7c:	b7b9                	j	800059ca <sys_open+0xe4>

0000000080005a7e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a7e:	7175                	addi	sp,sp,-144
    80005a80:	e506                	sd	ra,136(sp)
    80005a82:	e122                	sd	s0,128(sp)
    80005a84:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	890080e7          	jalr	-1904(ra) # 80004316 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a8e:	08000613          	li	a2,128
    80005a92:	f7040593          	addi	a1,s0,-144
    80005a96:	4501                	li	a0,0
    80005a98:	ffffd097          	auipc	ra,0xffffd
    80005a9c:	28a080e7          	jalr	650(ra) # 80002d22 <argstr>
    80005aa0:	02054963          	bltz	a0,80005ad2 <sys_mkdir+0x54>
    80005aa4:	4681                	li	a3,0
    80005aa6:	4601                	li	a2,0
    80005aa8:	4585                	li	a1,1
    80005aaa:	f7040513          	addi	a0,s0,-144
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	7fe080e7          	jalr	2046(ra) # 800052ac <create>
    80005ab6:	cd11                	beqz	a0,80005ad2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	0fe080e7          	jalr	254(ra) # 80003bb6 <iunlockput>
  end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	8d6080e7          	jalr	-1834(ra) # 80004396 <end_op>
  return 0;
    80005ac8:	4501                	li	a0,0
}
    80005aca:	60aa                	ld	ra,136(sp)
    80005acc:	640a                	ld	s0,128(sp)
    80005ace:	6149                	addi	sp,sp,144
    80005ad0:	8082                	ret
    end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	8c4080e7          	jalr	-1852(ra) # 80004396 <end_op>
    return -1;
    80005ada:	557d                	li	a0,-1
    80005adc:	b7fd                	j	80005aca <sys_mkdir+0x4c>

0000000080005ade <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ade:	7135                	addi	sp,sp,-160
    80005ae0:	ed06                	sd	ra,152(sp)
    80005ae2:	e922                	sd	s0,144(sp)
    80005ae4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	830080e7          	jalr	-2000(ra) # 80004316 <begin_op>
  argint(1, &major);
    80005aee:	f6c40593          	addi	a1,s0,-148
    80005af2:	4505                	li	a0,1
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	1ee080e7          	jalr	494(ra) # 80002ce2 <argint>
  argint(2, &minor);
    80005afc:	f6840593          	addi	a1,s0,-152
    80005b00:	4509                	li	a0,2
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	1e0080e7          	jalr	480(ra) # 80002ce2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b0a:	08000613          	li	a2,128
    80005b0e:	f7040593          	addi	a1,s0,-144
    80005b12:	4501                	li	a0,0
    80005b14:	ffffd097          	auipc	ra,0xffffd
    80005b18:	20e080e7          	jalr	526(ra) # 80002d22 <argstr>
    80005b1c:	02054b63          	bltz	a0,80005b52 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b20:	f6841683          	lh	a3,-152(s0)
    80005b24:	f6c41603          	lh	a2,-148(s0)
    80005b28:	458d                	li	a1,3
    80005b2a:	f7040513          	addi	a0,s0,-144
    80005b2e:	fffff097          	auipc	ra,0xfffff
    80005b32:	77e080e7          	jalr	1918(ra) # 800052ac <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b36:	cd11                	beqz	a0,80005b52 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	07e080e7          	jalr	126(ra) # 80003bb6 <iunlockput>
  end_op();
    80005b40:	fffff097          	auipc	ra,0xfffff
    80005b44:	856080e7          	jalr	-1962(ra) # 80004396 <end_op>
  return 0;
    80005b48:	4501                	li	a0,0
}
    80005b4a:	60ea                	ld	ra,152(sp)
    80005b4c:	644a                	ld	s0,144(sp)
    80005b4e:	610d                	addi	sp,sp,160
    80005b50:	8082                	ret
    end_op();
    80005b52:	fffff097          	auipc	ra,0xfffff
    80005b56:	844080e7          	jalr	-1980(ra) # 80004396 <end_op>
    return -1;
    80005b5a:	557d                	li	a0,-1
    80005b5c:	b7fd                	j	80005b4a <sys_mknod+0x6c>

0000000080005b5e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b5e:	7135                	addi	sp,sp,-160
    80005b60:	ed06                	sd	ra,152(sp)
    80005b62:	e922                	sd	s0,144(sp)
    80005b64:	e526                	sd	s1,136(sp)
    80005b66:	e14a                	sd	s2,128(sp)
    80005b68:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b6a:	ffffc097          	auipc	ra,0xffffc
    80005b6e:	e5c080e7          	jalr	-420(ra) # 800019c6 <myproc>
    80005b72:	892a                	mv	s2,a0
  
  begin_op();
    80005b74:	ffffe097          	auipc	ra,0xffffe
    80005b78:	7a2080e7          	jalr	1954(ra) # 80004316 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b7c:	08000613          	li	a2,128
    80005b80:	f6040593          	addi	a1,s0,-160
    80005b84:	4501                	li	a0,0
    80005b86:	ffffd097          	auipc	ra,0xffffd
    80005b8a:	19c080e7          	jalr	412(ra) # 80002d22 <argstr>
    80005b8e:	04054b63          	bltz	a0,80005be4 <sys_chdir+0x86>
    80005b92:	f6040513          	addi	a0,s0,-160
    80005b96:	ffffe097          	auipc	ra,0xffffe
    80005b9a:	564080e7          	jalr	1380(ra) # 800040fa <namei>
    80005b9e:	84aa                	mv	s1,a0
    80005ba0:	c131                	beqz	a0,80005be4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ba2:	ffffe097          	auipc	ra,0xffffe
    80005ba6:	db2080e7          	jalr	-590(ra) # 80003954 <ilock>
  if(ip->type != T_DIR){
    80005baa:	04449703          	lh	a4,68(s1)
    80005bae:	4785                	li	a5,1
    80005bb0:	04f71063          	bne	a4,a5,80005bf0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bb4:	8526                	mv	a0,s1
    80005bb6:	ffffe097          	auipc	ra,0xffffe
    80005bba:	e60080e7          	jalr	-416(ra) # 80003a16 <iunlock>
  iput(p->cwd);
    80005bbe:	15093503          	ld	a0,336(s2)
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	f4c080e7          	jalr	-180(ra) # 80003b0e <iput>
  end_op();
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	7cc080e7          	jalr	1996(ra) # 80004396 <end_op>
  p->cwd = ip;
    80005bd2:	14993823          	sd	s1,336(s2)
  return 0;
    80005bd6:	4501                	li	a0,0
}
    80005bd8:	60ea                	ld	ra,152(sp)
    80005bda:	644a                	ld	s0,144(sp)
    80005bdc:	64aa                	ld	s1,136(sp)
    80005bde:	690a                	ld	s2,128(sp)
    80005be0:	610d                	addi	sp,sp,160
    80005be2:	8082                	ret
    end_op();
    80005be4:	ffffe097          	auipc	ra,0xffffe
    80005be8:	7b2080e7          	jalr	1970(ra) # 80004396 <end_op>
    return -1;
    80005bec:	557d                	li	a0,-1
    80005bee:	b7ed                	j	80005bd8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bf0:	8526                	mv	a0,s1
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	fc4080e7          	jalr	-60(ra) # 80003bb6 <iunlockput>
    end_op();
    80005bfa:	ffffe097          	auipc	ra,0xffffe
    80005bfe:	79c080e7          	jalr	1948(ra) # 80004396 <end_op>
    return -1;
    80005c02:	557d                	li	a0,-1
    80005c04:	bfd1                	j	80005bd8 <sys_chdir+0x7a>

0000000080005c06 <sys_exec>:

uint64
sys_exec(void)
{
    80005c06:	7145                	addi	sp,sp,-464
    80005c08:	e786                	sd	ra,456(sp)
    80005c0a:	e3a2                	sd	s0,448(sp)
    80005c0c:	ff26                	sd	s1,440(sp)
    80005c0e:	fb4a                	sd	s2,432(sp)
    80005c10:	f74e                	sd	s3,424(sp)
    80005c12:	f352                	sd	s4,416(sp)
    80005c14:	ef56                	sd	s5,408(sp)
    80005c16:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c18:	e3840593          	addi	a1,s0,-456
    80005c1c:	4505                	li	a0,1
    80005c1e:	ffffd097          	auipc	ra,0xffffd
    80005c22:	0e4080e7          	jalr	228(ra) # 80002d02 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c26:	08000613          	li	a2,128
    80005c2a:	f4040593          	addi	a1,s0,-192
    80005c2e:	4501                	li	a0,0
    80005c30:	ffffd097          	auipc	ra,0xffffd
    80005c34:	0f2080e7          	jalr	242(ra) # 80002d22 <argstr>
    80005c38:	87aa                	mv	a5,a0
    return -1;
    80005c3a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c3c:	0c07c263          	bltz	a5,80005d00 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c40:	10000613          	li	a2,256
    80005c44:	4581                	li	a1,0
    80005c46:	e4040513          	addi	a0,s0,-448
    80005c4a:	ffffb097          	auipc	ra,0xffffb
    80005c4e:	09c080e7          	jalr	156(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c52:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c56:	89a6                	mv	s3,s1
    80005c58:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c5a:	02000a13          	li	s4,32
    80005c5e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c62:	00391513          	slli	a0,s2,0x3
    80005c66:	e3040593          	addi	a1,s0,-464
    80005c6a:	e3843783          	ld	a5,-456(s0)
    80005c6e:	953e                	add	a0,a0,a5
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	fd4080e7          	jalr	-44(ra) # 80002c44 <fetchaddr>
    80005c78:	02054a63          	bltz	a0,80005cac <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c7c:	e3043783          	ld	a5,-464(s0)
    80005c80:	c3b9                	beqz	a5,80005cc6 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c82:	ffffb097          	auipc	ra,0xffffb
    80005c86:	e78080e7          	jalr	-392(ra) # 80000afa <kalloc>
    80005c8a:	85aa                	mv	a1,a0
    80005c8c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c90:	cd11                	beqz	a0,80005cac <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c92:	6605                	lui	a2,0x1
    80005c94:	e3043503          	ld	a0,-464(s0)
    80005c98:	ffffd097          	auipc	ra,0xffffd
    80005c9c:	ffe080e7          	jalr	-2(ra) # 80002c96 <fetchstr>
    80005ca0:	00054663          	bltz	a0,80005cac <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ca4:	0905                	addi	s2,s2,1
    80005ca6:	09a1                	addi	s3,s3,8
    80005ca8:	fb491be3          	bne	s2,s4,80005c5e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cac:	10048913          	addi	s2,s1,256
    80005cb0:	6088                	ld	a0,0(s1)
    80005cb2:	c531                	beqz	a0,80005cfe <sys_exec+0xf8>
    kfree(argv[i]);
    80005cb4:	ffffb097          	auipc	ra,0xffffb
    80005cb8:	d4a080e7          	jalr	-694(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cbc:	04a1                	addi	s1,s1,8
    80005cbe:	ff2499e3          	bne	s1,s2,80005cb0 <sys_exec+0xaa>
  return -1;
    80005cc2:	557d                	li	a0,-1
    80005cc4:	a835                	j	80005d00 <sys_exec+0xfa>
      argv[i] = 0;
    80005cc6:	0a8e                	slli	s5,s5,0x3
    80005cc8:	fc040793          	addi	a5,s0,-64
    80005ccc:	9abe                	add	s5,s5,a5
    80005cce:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cd2:	e4040593          	addi	a1,s0,-448
    80005cd6:	f4040513          	addi	a0,s0,-192
    80005cda:	fffff097          	auipc	ra,0xfffff
    80005cde:	190080e7          	jalr	400(ra) # 80004e6a <exec>
    80005ce2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce4:	10048993          	addi	s3,s1,256
    80005ce8:	6088                	ld	a0,0(s1)
    80005cea:	c901                	beqz	a0,80005cfa <sys_exec+0xf4>
    kfree(argv[i]);
    80005cec:	ffffb097          	auipc	ra,0xffffb
    80005cf0:	d12080e7          	jalr	-750(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cf4:	04a1                	addi	s1,s1,8
    80005cf6:	ff3499e3          	bne	s1,s3,80005ce8 <sys_exec+0xe2>
  return ret;
    80005cfa:	854a                	mv	a0,s2
    80005cfc:	a011                	j	80005d00 <sys_exec+0xfa>
  return -1;
    80005cfe:	557d                	li	a0,-1
}
    80005d00:	60be                	ld	ra,456(sp)
    80005d02:	641e                	ld	s0,448(sp)
    80005d04:	74fa                	ld	s1,440(sp)
    80005d06:	795a                	ld	s2,432(sp)
    80005d08:	79ba                	ld	s3,424(sp)
    80005d0a:	7a1a                	ld	s4,416(sp)
    80005d0c:	6afa                	ld	s5,408(sp)
    80005d0e:	6179                	addi	sp,sp,464
    80005d10:	8082                	ret

0000000080005d12 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d12:	7139                	addi	sp,sp,-64
    80005d14:	fc06                	sd	ra,56(sp)
    80005d16:	f822                	sd	s0,48(sp)
    80005d18:	f426                	sd	s1,40(sp)
    80005d1a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d1c:	ffffc097          	auipc	ra,0xffffc
    80005d20:	caa080e7          	jalr	-854(ra) # 800019c6 <myproc>
    80005d24:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d26:	fd840593          	addi	a1,s0,-40
    80005d2a:	4501                	li	a0,0
    80005d2c:	ffffd097          	auipc	ra,0xffffd
    80005d30:	fd6080e7          	jalr	-42(ra) # 80002d02 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d34:	fc840593          	addi	a1,s0,-56
    80005d38:	fd040513          	addi	a0,s0,-48
    80005d3c:	fffff097          	auipc	ra,0xfffff
    80005d40:	dd6080e7          	jalr	-554(ra) # 80004b12 <pipealloc>
    return -1;
    80005d44:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d46:	0c054463          	bltz	a0,80005e0e <sys_pipe+0xfc>
  fd0 = -1;
    80005d4a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d4e:	fd043503          	ld	a0,-48(s0)
    80005d52:	fffff097          	auipc	ra,0xfffff
    80005d56:	518080e7          	jalr	1304(ra) # 8000526a <fdalloc>
    80005d5a:	fca42223          	sw	a0,-60(s0)
    80005d5e:	08054b63          	bltz	a0,80005df4 <sys_pipe+0xe2>
    80005d62:	fc843503          	ld	a0,-56(s0)
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	504080e7          	jalr	1284(ra) # 8000526a <fdalloc>
    80005d6e:	fca42023          	sw	a0,-64(s0)
    80005d72:	06054863          	bltz	a0,80005de2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d76:	4691                	li	a3,4
    80005d78:	fc440613          	addi	a2,s0,-60
    80005d7c:	fd843583          	ld	a1,-40(s0)
    80005d80:	68a8                	ld	a0,80(s1)
    80005d82:	ffffc097          	auipc	ra,0xffffc
    80005d86:	902080e7          	jalr	-1790(ra) # 80001684 <copyout>
    80005d8a:	02054063          	bltz	a0,80005daa <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d8e:	4691                	li	a3,4
    80005d90:	fc040613          	addi	a2,s0,-64
    80005d94:	fd843583          	ld	a1,-40(s0)
    80005d98:	0591                	addi	a1,a1,4
    80005d9a:	68a8                	ld	a0,80(s1)
    80005d9c:	ffffc097          	auipc	ra,0xffffc
    80005da0:	8e8080e7          	jalr	-1816(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005da4:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005da6:	06055463          	bgez	a0,80005e0e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005daa:	fc442783          	lw	a5,-60(s0)
    80005dae:	07e9                	addi	a5,a5,26
    80005db0:	078e                	slli	a5,a5,0x3
    80005db2:	97a6                	add	a5,a5,s1
    80005db4:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005db8:	fc042503          	lw	a0,-64(s0)
    80005dbc:	0569                	addi	a0,a0,26
    80005dbe:	050e                	slli	a0,a0,0x3
    80005dc0:	94aa                	add	s1,s1,a0
    80005dc2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dc6:	fd043503          	ld	a0,-48(s0)
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	a18080e7          	jalr	-1512(ra) # 800047e2 <fileclose>
    fileclose(wf);
    80005dd2:	fc843503          	ld	a0,-56(s0)
    80005dd6:	fffff097          	auipc	ra,0xfffff
    80005dda:	a0c080e7          	jalr	-1524(ra) # 800047e2 <fileclose>
    return -1;
    80005dde:	57fd                	li	a5,-1
    80005de0:	a03d                	j	80005e0e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005de2:	fc442783          	lw	a5,-60(s0)
    80005de6:	0007c763          	bltz	a5,80005df4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005dea:	07e9                	addi	a5,a5,26
    80005dec:	078e                	slli	a5,a5,0x3
    80005dee:	94be                	add	s1,s1,a5
    80005df0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005df4:	fd043503          	ld	a0,-48(s0)
    80005df8:	fffff097          	auipc	ra,0xfffff
    80005dfc:	9ea080e7          	jalr	-1558(ra) # 800047e2 <fileclose>
    fileclose(wf);
    80005e00:	fc843503          	ld	a0,-56(s0)
    80005e04:	fffff097          	auipc	ra,0xfffff
    80005e08:	9de080e7          	jalr	-1570(ra) # 800047e2 <fileclose>
    return -1;
    80005e0c:	57fd                	li	a5,-1
}
    80005e0e:	853e                	mv	a0,a5
    80005e10:	70e2                	ld	ra,56(sp)
    80005e12:	7442                	ld	s0,48(sp)
    80005e14:	74a2                	ld	s1,40(sp)
    80005e16:	6121                	addi	sp,sp,64
    80005e18:	8082                	ret
    80005e1a:	0000                	unimp
    80005e1c:	0000                	unimp
	...

0000000080005e20 <kernelvec>:
    80005e20:	7111                	addi	sp,sp,-256
    80005e22:	e006                	sd	ra,0(sp)
    80005e24:	e40a                	sd	sp,8(sp)
    80005e26:	e80e                	sd	gp,16(sp)
    80005e28:	ec12                	sd	tp,24(sp)
    80005e2a:	f016                	sd	t0,32(sp)
    80005e2c:	f41a                	sd	t1,40(sp)
    80005e2e:	f81e                	sd	t2,48(sp)
    80005e30:	fc22                	sd	s0,56(sp)
    80005e32:	e0a6                	sd	s1,64(sp)
    80005e34:	e4aa                	sd	a0,72(sp)
    80005e36:	e8ae                	sd	a1,80(sp)
    80005e38:	ecb2                	sd	a2,88(sp)
    80005e3a:	f0b6                	sd	a3,96(sp)
    80005e3c:	f4ba                	sd	a4,104(sp)
    80005e3e:	f8be                	sd	a5,112(sp)
    80005e40:	fcc2                	sd	a6,120(sp)
    80005e42:	e146                	sd	a7,128(sp)
    80005e44:	e54a                	sd	s2,136(sp)
    80005e46:	e94e                	sd	s3,144(sp)
    80005e48:	ed52                	sd	s4,152(sp)
    80005e4a:	f156                	sd	s5,160(sp)
    80005e4c:	f55a                	sd	s6,168(sp)
    80005e4e:	f95e                	sd	s7,176(sp)
    80005e50:	fd62                	sd	s8,184(sp)
    80005e52:	e1e6                	sd	s9,192(sp)
    80005e54:	e5ea                	sd	s10,200(sp)
    80005e56:	e9ee                	sd	s11,208(sp)
    80005e58:	edf2                	sd	t3,216(sp)
    80005e5a:	f1f6                	sd	t4,224(sp)
    80005e5c:	f5fa                	sd	t5,232(sp)
    80005e5e:	f9fe                	sd	t6,240(sp)
    80005e60:	cb1fc0ef          	jal	ra,80002b10 <kerneltrap>
    80005e64:	6082                	ld	ra,0(sp)
    80005e66:	6122                	ld	sp,8(sp)
    80005e68:	61c2                	ld	gp,16(sp)
    80005e6a:	7282                	ld	t0,32(sp)
    80005e6c:	7322                	ld	t1,40(sp)
    80005e6e:	73c2                	ld	t2,48(sp)
    80005e70:	7462                	ld	s0,56(sp)
    80005e72:	6486                	ld	s1,64(sp)
    80005e74:	6526                	ld	a0,72(sp)
    80005e76:	65c6                	ld	a1,80(sp)
    80005e78:	6666                	ld	a2,88(sp)
    80005e7a:	7686                	ld	a3,96(sp)
    80005e7c:	7726                	ld	a4,104(sp)
    80005e7e:	77c6                	ld	a5,112(sp)
    80005e80:	7866                	ld	a6,120(sp)
    80005e82:	688a                	ld	a7,128(sp)
    80005e84:	692a                	ld	s2,136(sp)
    80005e86:	69ca                	ld	s3,144(sp)
    80005e88:	6a6a                	ld	s4,152(sp)
    80005e8a:	7a8a                	ld	s5,160(sp)
    80005e8c:	7b2a                	ld	s6,168(sp)
    80005e8e:	7bca                	ld	s7,176(sp)
    80005e90:	7c6a                	ld	s8,184(sp)
    80005e92:	6c8e                	ld	s9,192(sp)
    80005e94:	6d2e                	ld	s10,200(sp)
    80005e96:	6dce                	ld	s11,208(sp)
    80005e98:	6e6e                	ld	t3,216(sp)
    80005e9a:	7e8e                	ld	t4,224(sp)
    80005e9c:	7f2e                	ld	t5,232(sp)
    80005e9e:	7fce                	ld	t6,240(sp)
    80005ea0:	6111                	addi	sp,sp,256
    80005ea2:	10200073          	sret
    80005ea6:	00000013          	nop
    80005eaa:	00000013          	nop
    80005eae:	0001                	nop

0000000080005eb0 <timervec>:
    80005eb0:	34051573          	csrrw	a0,mscratch,a0
    80005eb4:	e10c                	sd	a1,0(a0)
    80005eb6:	e510                	sd	a2,8(a0)
    80005eb8:	e914                	sd	a3,16(a0)
    80005eba:	6d0c                	ld	a1,24(a0)
    80005ebc:	7110                	ld	a2,32(a0)
    80005ebe:	6194                	ld	a3,0(a1)
    80005ec0:	96b2                	add	a3,a3,a2
    80005ec2:	e194                	sd	a3,0(a1)
    80005ec4:	4589                	li	a1,2
    80005ec6:	14459073          	csrw	sip,a1
    80005eca:	6914                	ld	a3,16(a0)
    80005ecc:	6510                	ld	a2,8(a0)
    80005ece:	610c                	ld	a1,0(a0)
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	30200073          	mret
	...

0000000080005eda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eda:	1141                	addi	sp,sp,-16
    80005edc:	e422                	sd	s0,8(sp)
    80005ede:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005ee0:	0c0007b7          	lui	a5,0xc000
    80005ee4:	4705                	li	a4,1
    80005ee6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005ee8:	c3d8                	sw	a4,4(a5)
}
    80005eea:	6422                	ld	s0,8(sp)
    80005eec:	0141                	addi	sp,sp,16
    80005eee:	8082                	ret

0000000080005ef0 <plicinithart>:

void
plicinithart(void)
{
    80005ef0:	1141                	addi	sp,sp,-16
    80005ef2:	e406                	sd	ra,8(sp)
    80005ef4:	e022                	sd	s0,0(sp)
    80005ef6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	aa2080e7          	jalr	-1374(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f00:	0085171b          	slliw	a4,a0,0x8
    80005f04:	0c0027b7          	lui	a5,0xc002
    80005f08:	97ba                	add	a5,a5,a4
    80005f0a:	40200713          	li	a4,1026
    80005f0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f12:	00d5151b          	slliw	a0,a0,0xd
    80005f16:	0c2017b7          	lui	a5,0xc201
    80005f1a:	953e                	add	a0,a0,a5
    80005f1c:	00052023          	sw	zero,0(a0)
}
    80005f20:	60a2                	ld	ra,8(sp)
    80005f22:	6402                	ld	s0,0(sp)
    80005f24:	0141                	addi	sp,sp,16
    80005f26:	8082                	ret

0000000080005f28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f28:	1141                	addi	sp,sp,-16
    80005f2a:	e406                	sd	ra,8(sp)
    80005f2c:	e022                	sd	s0,0(sp)
    80005f2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	a6a080e7          	jalr	-1430(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f38:	00d5179b          	slliw	a5,a0,0xd
    80005f3c:	0c201537          	lui	a0,0xc201
    80005f40:	953e                	add	a0,a0,a5
  return irq;
}
    80005f42:	4148                	lw	a0,4(a0)
    80005f44:	60a2                	ld	ra,8(sp)
    80005f46:	6402                	ld	s0,0(sp)
    80005f48:	0141                	addi	sp,sp,16
    80005f4a:	8082                	ret

0000000080005f4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f4c:	1101                	addi	sp,sp,-32
    80005f4e:	ec06                	sd	ra,24(sp)
    80005f50:	e822                	sd	s0,16(sp)
    80005f52:	e426                	sd	s1,8(sp)
    80005f54:	1000                	addi	s0,sp,32
    80005f56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	a42080e7          	jalr	-1470(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f60:	00d5151b          	slliw	a0,a0,0xd
    80005f64:	0c2017b7          	lui	a5,0xc201
    80005f68:	97aa                	add	a5,a5,a0
    80005f6a:	c3c4                	sw	s1,4(a5)
}
    80005f6c:	60e2                	ld	ra,24(sp)
    80005f6e:	6442                	ld	s0,16(sp)
    80005f70:	64a2                	ld	s1,8(sp)
    80005f72:	6105                	addi	sp,sp,32
    80005f74:	8082                	ret

0000000080005f76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f76:	1141                	addi	sp,sp,-16
    80005f78:	e406                	sd	ra,8(sp)
    80005f7a:	e022                	sd	s0,0(sp)
    80005f7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f7e:	479d                	li	a5,7
    80005f80:	04a7cc63          	blt	a5,a0,80005fd8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f84:	0001c797          	auipc	a5,0x1c
    80005f88:	c8c78793          	addi	a5,a5,-884 # 80021c10 <disk>
    80005f8c:	97aa                	add	a5,a5,a0
    80005f8e:	0187c783          	lbu	a5,24(a5)
    80005f92:	ebb9                	bnez	a5,80005fe8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f94:	00451613          	slli	a2,a0,0x4
    80005f98:	0001c797          	auipc	a5,0x1c
    80005f9c:	c7878793          	addi	a5,a5,-904 # 80021c10 <disk>
    80005fa0:	6394                	ld	a3,0(a5)
    80005fa2:	96b2                	add	a3,a3,a2
    80005fa4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fa8:	6398                	ld	a4,0(a5)
    80005faa:	9732                	add	a4,a4,a2
    80005fac:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fb0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fb4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fb8:	953e                	add	a0,a0,a5
    80005fba:	4785                	li	a5,1
    80005fbc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005fc0:	0001c517          	auipc	a0,0x1c
    80005fc4:	c6850513          	addi	a0,a0,-920 # 80021c28 <disk+0x18>
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	106080e7          	jalr	262(ra) # 800020ce <wakeup>
}
    80005fd0:	60a2                	ld	ra,8(sp)
    80005fd2:	6402                	ld	s0,0(sp)
    80005fd4:	0141                	addi	sp,sp,16
    80005fd6:	8082                	ret
    panic("free_desc 1");
    80005fd8:	00002517          	auipc	a0,0x2
    80005fdc:	77850513          	addi	a0,a0,1912 # 80008750 <syscalls+0x300>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005fe8:	00002517          	auipc	a0,0x2
    80005fec:	77850513          	addi	a0,a0,1912 # 80008760 <syscalls+0x310>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	554080e7          	jalr	1364(ra) # 80000544 <panic>

0000000080005ff8 <virtio_disk_init>:
{
    80005ff8:	1101                	addi	sp,sp,-32
    80005ffa:	ec06                	sd	ra,24(sp)
    80005ffc:	e822                	sd	s0,16(sp)
    80005ffe:	e426                	sd	s1,8(sp)
    80006000:	e04a                	sd	s2,0(sp)
    80006002:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006004:	00002597          	auipc	a1,0x2
    80006008:	76c58593          	addi	a1,a1,1900 # 80008770 <syscalls+0x320>
    8000600c:	0001c517          	auipc	a0,0x1c
    80006010:	d2c50513          	addi	a0,a0,-724 # 80021d38 <disk+0x128>
    80006014:	ffffb097          	auipc	ra,0xffffb
    80006018:	b46080e7          	jalr	-1210(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000601c:	100017b7          	lui	a5,0x10001
    80006020:	4398                	lw	a4,0(a5)
    80006022:	2701                	sext.w	a4,a4
    80006024:	747277b7          	lui	a5,0x74727
    80006028:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000602c:	14f71e63          	bne	a4,a5,80006188 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006030:	100017b7          	lui	a5,0x10001
    80006034:	43dc                	lw	a5,4(a5)
    80006036:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006038:	4709                	li	a4,2
    8000603a:	14e79763          	bne	a5,a4,80006188 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000603e:	100017b7          	lui	a5,0x10001
    80006042:	479c                	lw	a5,8(a5)
    80006044:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006046:	14e79163          	bne	a5,a4,80006188 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	47d8                	lw	a4,12(a5)
    80006050:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006052:	554d47b7          	lui	a5,0x554d4
    80006056:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000605a:	12f71763          	bne	a4,a5,80006188 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006066:	4705                	li	a4,1
    80006068:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000606a:	470d                	li	a4,3
    8000606c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000606e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006070:	c7ffe737          	lui	a4,0xc7ffe
    80006074:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdca0f>
    80006078:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000607a:	2701                	sext.w	a4,a4
    8000607c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	472d                	li	a4,11
    80006080:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006082:	0707a903          	lw	s2,112(a5)
    80006086:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006088:	00897793          	andi	a5,s2,8
    8000608c:	10078663          	beqz	a5,80006198 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006090:	100017b7          	lui	a5,0x10001
    80006094:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006098:	43fc                	lw	a5,68(a5)
    8000609a:	2781                	sext.w	a5,a5
    8000609c:	10079663          	bnez	a5,800061a8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060a0:	100017b7          	lui	a5,0x10001
    800060a4:	5bdc                	lw	a5,52(a5)
    800060a6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060a8:	10078863          	beqz	a5,800061b8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800060ac:	471d                	li	a4,7
    800060ae:	10f77d63          	bgeu	a4,a5,800061c8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800060b2:	ffffb097          	auipc	ra,0xffffb
    800060b6:	a48080e7          	jalr	-1464(ra) # 80000afa <kalloc>
    800060ba:	0001c497          	auipc	s1,0x1c
    800060be:	b5648493          	addi	s1,s1,-1194 # 80021c10 <disk>
    800060c2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060c4:	ffffb097          	auipc	ra,0xffffb
    800060c8:	a36080e7          	jalr	-1482(ra) # 80000afa <kalloc>
    800060cc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ce:	ffffb097          	auipc	ra,0xffffb
    800060d2:	a2c080e7          	jalr	-1492(ra) # 80000afa <kalloc>
    800060d6:	87aa                	mv	a5,a0
    800060d8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060da:	6088                	ld	a0,0(s1)
    800060dc:	cd75                	beqz	a0,800061d8 <virtio_disk_init+0x1e0>
    800060de:	0001c717          	auipc	a4,0x1c
    800060e2:	b3a73703          	ld	a4,-1222(a4) # 80021c18 <disk+0x8>
    800060e6:	cb6d                	beqz	a4,800061d8 <virtio_disk_init+0x1e0>
    800060e8:	cbe5                	beqz	a5,800061d8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800060ea:	6605                	lui	a2,0x1
    800060ec:	4581                	li	a1,0
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	bf8080e7          	jalr	-1032(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060f6:	0001c497          	auipc	s1,0x1c
    800060fa:	b1a48493          	addi	s1,s1,-1254 # 80021c10 <disk>
    800060fe:	6605                	lui	a2,0x1
    80006100:	4581                	li	a1,0
    80006102:	6488                	ld	a0,8(s1)
    80006104:	ffffb097          	auipc	ra,0xffffb
    80006108:	be2080e7          	jalr	-1054(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000610c:	6605                	lui	a2,0x1
    8000610e:	4581                	li	a1,0
    80006110:	6888                	ld	a0,16(s1)
    80006112:	ffffb097          	auipc	ra,0xffffb
    80006116:	bd4080e7          	jalr	-1068(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000611a:	100017b7          	lui	a5,0x10001
    8000611e:	4721                	li	a4,8
    80006120:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006122:	4098                	lw	a4,0(s1)
    80006124:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006128:	40d8                	lw	a4,4(s1)
    8000612a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000612e:	6498                	ld	a4,8(s1)
    80006130:	0007069b          	sext.w	a3,a4
    80006134:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006138:	9701                	srai	a4,a4,0x20
    8000613a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000613e:	6898                	ld	a4,16(s1)
    80006140:	0007069b          	sext.w	a3,a4
    80006144:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006148:	9701                	srai	a4,a4,0x20
    8000614a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000614e:	4685                	li	a3,1
    80006150:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006152:	4705                	li	a4,1
    80006154:	00d48c23          	sb	a3,24(s1)
    80006158:	00e48ca3          	sb	a4,25(s1)
    8000615c:	00e48d23          	sb	a4,26(s1)
    80006160:	00e48da3          	sb	a4,27(s1)
    80006164:	00e48e23          	sb	a4,28(s1)
    80006168:	00e48ea3          	sb	a4,29(s1)
    8000616c:	00e48f23          	sb	a4,30(s1)
    80006170:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006174:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006178:	0727a823          	sw	s2,112(a5)
}
    8000617c:	60e2                	ld	ra,24(sp)
    8000617e:	6442                	ld	s0,16(sp)
    80006180:	64a2                	ld	s1,8(sp)
    80006182:	6902                	ld	s2,0(sp)
    80006184:	6105                	addi	sp,sp,32
    80006186:	8082                	ret
    panic("could not find virtio disk");
    80006188:	00002517          	auipc	a0,0x2
    8000618c:	5f850513          	addi	a0,a0,1528 # 80008780 <syscalls+0x330>
    80006190:	ffffa097          	auipc	ra,0xffffa
    80006194:	3b4080e7          	jalr	948(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006198:	00002517          	auipc	a0,0x2
    8000619c:	60850513          	addi	a0,a0,1544 # 800087a0 <syscalls+0x350>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	3a4080e7          	jalr	932(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	61850513          	addi	a0,a0,1560 # 800087c0 <syscalls+0x370>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	394080e7          	jalr	916(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	62850513          	addi	a0,a0,1576 # 800087e0 <syscalls+0x390>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	384080e7          	jalr	900(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800061c8:	00002517          	auipc	a0,0x2
    800061cc:	63850513          	addi	a0,a0,1592 # 80008800 <syscalls+0x3b0>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	374080e7          	jalr	884(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800061d8:	00002517          	auipc	a0,0x2
    800061dc:	64850513          	addi	a0,a0,1608 # 80008820 <syscalls+0x3d0>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	364080e7          	jalr	868(ra) # 80000544 <panic>

00000000800061e8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061e8:	7159                	addi	sp,sp,-112
    800061ea:	f486                	sd	ra,104(sp)
    800061ec:	f0a2                	sd	s0,96(sp)
    800061ee:	eca6                	sd	s1,88(sp)
    800061f0:	e8ca                	sd	s2,80(sp)
    800061f2:	e4ce                	sd	s3,72(sp)
    800061f4:	e0d2                	sd	s4,64(sp)
    800061f6:	fc56                	sd	s5,56(sp)
    800061f8:	f85a                	sd	s6,48(sp)
    800061fa:	f45e                	sd	s7,40(sp)
    800061fc:	f062                	sd	s8,32(sp)
    800061fe:	ec66                	sd	s9,24(sp)
    80006200:	e86a                	sd	s10,16(sp)
    80006202:	1880                	addi	s0,sp,112
    80006204:	892a                	mv	s2,a0
    80006206:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006208:	00c52c83          	lw	s9,12(a0)
    8000620c:	001c9c9b          	slliw	s9,s9,0x1
    80006210:	1c82                	slli	s9,s9,0x20
    80006212:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006216:	0001c517          	auipc	a0,0x1c
    8000621a:	b2250513          	addi	a0,a0,-1246 # 80021d38 <disk+0x128>
    8000621e:	ffffb097          	auipc	ra,0xffffb
    80006222:	9cc080e7          	jalr	-1588(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006226:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006228:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000622a:	0001cb17          	auipc	s6,0x1c
    8000622e:	9e6b0b13          	addi	s6,s6,-1562 # 80021c10 <disk>
  for(int i = 0; i < 3; i++){
    80006232:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006234:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006236:	0001cc17          	auipc	s8,0x1c
    8000623a:	b02c0c13          	addi	s8,s8,-1278 # 80021d38 <disk+0x128>
    8000623e:	a8b5                	j	800062ba <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006240:	00fb06b3          	add	a3,s6,a5
    80006244:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006248:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000624a:	0207c563          	bltz	a5,80006274 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000624e:	2485                	addiw	s1,s1,1
    80006250:	0711                	addi	a4,a4,4
    80006252:	1f548a63          	beq	s1,s5,80006446 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006256:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006258:	0001c697          	auipc	a3,0x1c
    8000625c:	9b868693          	addi	a3,a3,-1608 # 80021c10 <disk>
    80006260:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006262:	0186c583          	lbu	a1,24(a3)
    80006266:	fde9                	bnez	a1,80006240 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006268:	2785                	addiw	a5,a5,1
    8000626a:	0685                	addi	a3,a3,1
    8000626c:	ff779be3          	bne	a5,s7,80006262 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006270:	57fd                	li	a5,-1
    80006272:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006274:	02905a63          	blez	s1,800062a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006278:	f9042503          	lw	a0,-112(s0)
    8000627c:	00000097          	auipc	ra,0x0
    80006280:	cfa080e7          	jalr	-774(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006284:	4785                	li	a5,1
    80006286:	0297d163          	bge	a5,s1,800062a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000628a:	f9442503          	lw	a0,-108(s0)
    8000628e:	00000097          	auipc	ra,0x0
    80006292:	ce8080e7          	jalr	-792(ra) # 80005f76 <free_desc>
      for(int j = 0; j < i; j++)
    80006296:	4789                	li	a5,2
    80006298:	0097d863          	bge	a5,s1,800062a8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000629c:	f9842503          	lw	a0,-104(s0)
    800062a0:	00000097          	auipc	ra,0x0
    800062a4:	cd6080e7          	jalr	-810(ra) # 80005f76 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a8:	85e2                	mv	a1,s8
    800062aa:	0001c517          	auipc	a0,0x1c
    800062ae:	97e50513          	addi	a0,a0,-1666 # 80021c28 <disk+0x18>
    800062b2:	ffffc097          	auipc	ra,0xffffc
    800062b6:	db8080e7          	jalr	-584(ra) # 8000206a <sleep>
  for(int i = 0; i < 3; i++){
    800062ba:	f9040713          	addi	a4,s0,-112
    800062be:	84ce                	mv	s1,s3
    800062c0:	bf59                	j	80006256 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800062c2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800062c6:	00479693          	slli	a3,a5,0x4
    800062ca:	0001c797          	auipc	a5,0x1c
    800062ce:	94678793          	addi	a5,a5,-1722 # 80021c10 <disk>
    800062d2:	97b6                	add	a5,a5,a3
    800062d4:	4685                	li	a3,1
    800062d6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062d8:	0001c597          	auipc	a1,0x1c
    800062dc:	93858593          	addi	a1,a1,-1736 # 80021c10 <disk>
    800062e0:	00a60793          	addi	a5,a2,10
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	97ae                	add	a5,a5,a1
    800062e8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800062ec:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062f0:	f6070693          	addi	a3,a4,-160
    800062f4:	619c                	ld	a5,0(a1)
    800062f6:	97b6                	add	a5,a5,a3
    800062f8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062fa:	6188                	ld	a0,0(a1)
    800062fc:	96aa                	add	a3,a3,a0
    800062fe:	47c1                	li	a5,16
    80006300:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006302:	4785                	li	a5,1
    80006304:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006308:	f9442783          	lw	a5,-108(s0)
    8000630c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006310:	0792                	slli	a5,a5,0x4
    80006312:	953e                	add	a0,a0,a5
    80006314:	05890693          	addi	a3,s2,88
    80006318:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000631a:	6188                	ld	a0,0(a1)
    8000631c:	97aa                	add	a5,a5,a0
    8000631e:	40000693          	li	a3,1024
    80006322:	c794                	sw	a3,8(a5)
  if(write)
    80006324:	100d0d63          	beqz	s10,8000643e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006328:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000632c:	00c7d683          	lhu	a3,12(a5)
    80006330:	0016e693          	ori	a3,a3,1
    80006334:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006338:	f9842583          	lw	a1,-104(s0)
    8000633c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006340:	0001c697          	auipc	a3,0x1c
    80006344:	8d068693          	addi	a3,a3,-1840 # 80021c10 <disk>
    80006348:	00260793          	addi	a5,a2,2
    8000634c:	0792                	slli	a5,a5,0x4
    8000634e:	97b6                	add	a5,a5,a3
    80006350:	587d                	li	a6,-1
    80006352:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006356:	0592                	slli	a1,a1,0x4
    80006358:	952e                	add	a0,a0,a1
    8000635a:	f9070713          	addi	a4,a4,-112
    8000635e:	9736                	add	a4,a4,a3
    80006360:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006362:	6298                	ld	a4,0(a3)
    80006364:	972e                	add	a4,a4,a1
    80006366:	4585                	li	a1,1
    80006368:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000636a:	4509                	li	a0,2
    8000636c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006370:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006374:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006378:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000637c:	6698                	ld	a4,8(a3)
    8000637e:	00275783          	lhu	a5,2(a4)
    80006382:	8b9d                	andi	a5,a5,7
    80006384:	0786                	slli	a5,a5,0x1
    80006386:	97ba                	add	a5,a5,a4
    80006388:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000638c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006390:	6698                	ld	a4,8(a3)
    80006392:	00275783          	lhu	a5,2(a4)
    80006396:	2785                	addiw	a5,a5,1
    80006398:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000639c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063a0:	100017b7          	lui	a5,0x10001
    800063a4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063a8:	00492703          	lw	a4,4(s2)
    800063ac:	4785                	li	a5,1
    800063ae:	02f71163          	bne	a4,a5,800063d0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800063b2:	0001c997          	auipc	s3,0x1c
    800063b6:	98698993          	addi	s3,s3,-1658 # 80021d38 <disk+0x128>
  while(b->disk == 1) {
    800063ba:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063bc:	85ce                	mv	a1,s3
    800063be:	854a                	mv	a0,s2
    800063c0:	ffffc097          	auipc	ra,0xffffc
    800063c4:	caa080e7          	jalr	-854(ra) # 8000206a <sleep>
  while(b->disk == 1) {
    800063c8:	00492783          	lw	a5,4(s2)
    800063cc:	fe9788e3          	beq	a5,s1,800063bc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800063d0:	f9042903          	lw	s2,-112(s0)
    800063d4:	00290793          	addi	a5,s2,2
    800063d8:	00479713          	slli	a4,a5,0x4
    800063dc:	0001c797          	auipc	a5,0x1c
    800063e0:	83478793          	addi	a5,a5,-1996 # 80021c10 <disk>
    800063e4:	97ba                	add	a5,a5,a4
    800063e6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063ea:	0001c997          	auipc	s3,0x1c
    800063ee:	82698993          	addi	s3,s3,-2010 # 80021c10 <disk>
    800063f2:	00491713          	slli	a4,s2,0x4
    800063f6:	0009b783          	ld	a5,0(s3)
    800063fa:	97ba                	add	a5,a5,a4
    800063fc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006400:	854a                	mv	a0,s2
    80006402:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006406:	00000097          	auipc	ra,0x0
    8000640a:	b70080e7          	jalr	-1168(ra) # 80005f76 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000640e:	8885                	andi	s1,s1,1
    80006410:	f0ed                	bnez	s1,800063f2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006412:	0001c517          	auipc	a0,0x1c
    80006416:	92650513          	addi	a0,a0,-1754 # 80021d38 <disk+0x128>
    8000641a:	ffffb097          	auipc	ra,0xffffb
    8000641e:	884080e7          	jalr	-1916(ra) # 80000c9e <release>
}
    80006422:	70a6                	ld	ra,104(sp)
    80006424:	7406                	ld	s0,96(sp)
    80006426:	64e6                	ld	s1,88(sp)
    80006428:	6946                	ld	s2,80(sp)
    8000642a:	69a6                	ld	s3,72(sp)
    8000642c:	6a06                	ld	s4,64(sp)
    8000642e:	7ae2                	ld	s5,56(sp)
    80006430:	7b42                	ld	s6,48(sp)
    80006432:	7ba2                	ld	s7,40(sp)
    80006434:	7c02                	ld	s8,32(sp)
    80006436:	6ce2                	ld	s9,24(sp)
    80006438:	6d42                	ld	s10,16(sp)
    8000643a:	6165                	addi	sp,sp,112
    8000643c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000643e:	4689                	li	a3,2
    80006440:	00d79623          	sh	a3,12(a5)
    80006444:	b5e5                	j	8000632c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006446:	f9042603          	lw	a2,-112(s0)
    8000644a:	00a60713          	addi	a4,a2,10
    8000644e:	0712                	slli	a4,a4,0x4
    80006450:	0001b517          	auipc	a0,0x1b
    80006454:	7c850513          	addi	a0,a0,1992 # 80021c18 <disk+0x8>
    80006458:	953a                	add	a0,a0,a4
  if(write)
    8000645a:	e60d14e3          	bnez	s10,800062c2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000645e:	00a60793          	addi	a5,a2,10
    80006462:	00479693          	slli	a3,a5,0x4
    80006466:	0001b797          	auipc	a5,0x1b
    8000646a:	7aa78793          	addi	a5,a5,1962 # 80021c10 <disk>
    8000646e:	97b6                	add	a5,a5,a3
    80006470:	0007a423          	sw	zero,8(a5)
    80006474:	b595                	j	800062d8 <virtio_disk_rw+0xf0>

0000000080006476 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006476:	1101                	addi	sp,sp,-32
    80006478:	ec06                	sd	ra,24(sp)
    8000647a:	e822                	sd	s0,16(sp)
    8000647c:	e426                	sd	s1,8(sp)
    8000647e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006480:	0001b497          	auipc	s1,0x1b
    80006484:	79048493          	addi	s1,s1,1936 # 80021c10 <disk>
    80006488:	0001c517          	auipc	a0,0x1c
    8000648c:	8b050513          	addi	a0,a0,-1872 # 80021d38 <disk+0x128>
    80006490:	ffffa097          	auipc	ra,0xffffa
    80006494:	75a080e7          	jalr	1882(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006498:	10001737          	lui	a4,0x10001
    8000649c:	533c                	lw	a5,96(a4)
    8000649e:	8b8d                	andi	a5,a5,3
    800064a0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064a2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064a6:	689c                	ld	a5,16(s1)
    800064a8:	0204d703          	lhu	a4,32(s1)
    800064ac:	0027d783          	lhu	a5,2(a5)
    800064b0:	04f70863          	beq	a4,a5,80006500 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064b4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064b8:	6898                	ld	a4,16(s1)
    800064ba:	0204d783          	lhu	a5,32(s1)
    800064be:	8b9d                	andi	a5,a5,7
    800064c0:	078e                	slli	a5,a5,0x3
    800064c2:	97ba                	add	a5,a5,a4
    800064c4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064c6:	00278713          	addi	a4,a5,2
    800064ca:	0712                	slli	a4,a4,0x4
    800064cc:	9726                	add	a4,a4,s1
    800064ce:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064d2:	e721                	bnez	a4,8000651a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064d4:	0789                	addi	a5,a5,2
    800064d6:	0792                	slli	a5,a5,0x4
    800064d8:	97a6                	add	a5,a5,s1
    800064da:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064dc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064e0:	ffffc097          	auipc	ra,0xffffc
    800064e4:	bee080e7          	jalr	-1042(ra) # 800020ce <wakeup>

    disk.used_idx += 1;
    800064e8:	0204d783          	lhu	a5,32(s1)
    800064ec:	2785                	addiw	a5,a5,1
    800064ee:	17c2                	slli	a5,a5,0x30
    800064f0:	93c1                	srli	a5,a5,0x30
    800064f2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064f6:	6898                	ld	a4,16(s1)
    800064f8:	00275703          	lhu	a4,2(a4)
    800064fc:	faf71ce3          	bne	a4,a5,800064b4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006500:	0001c517          	auipc	a0,0x1c
    80006504:	83850513          	addi	a0,a0,-1992 # 80021d38 <disk+0x128>
    80006508:	ffffa097          	auipc	ra,0xffffa
    8000650c:	796080e7          	jalr	1942(ra) # 80000c9e <release>
}
    80006510:	60e2                	ld	ra,24(sp)
    80006512:	6442                	ld	s0,16(sp)
    80006514:	64a2                	ld	s1,8(sp)
    80006516:	6105                	addi	sp,sp,32
    80006518:	8082                	ret
      panic("virtio_disk_intr status");
    8000651a:	00002517          	auipc	a0,0x2
    8000651e:	31e50513          	addi	a0,a0,798 # 80008838 <syscalls+0x3e8>
    80006522:	ffffa097          	auipc	ra,0xffffa
    80006526:	022080e7          	jalr	34(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
