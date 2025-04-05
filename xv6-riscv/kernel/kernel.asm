
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
    80000068:	e6c78793          	addi	a5,a5,-404 # 80005ed0 <timervec>
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
    80000130:	65c080e7          	jalr	1628(ra) # 80002788 <either_copyin>
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
    800001d0:	1fa080e7          	jalr	506(ra) # 800023c6 <killed>
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
    8000021a:	51c080e7          	jalr	1308(ra) # 80002732 <either_copyout>
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
    800002fc:	4e6080e7          	jalr	1254(ra) # 800027de <procdump>
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
    80000ede:	a44080e7          	jalr	-1468(ra) # 8000291e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	02e080e7          	jalr	46(ra) # 80005f10 <plicinithart>
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
    80000f56:	9a4080e7          	jalr	-1628(ra) # 800028f6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	9c4080e7          	jalr	-1596(ra) # 8000291e <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f98080e7          	jalr	-104(ra) # 80005efa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	fa6080e7          	jalr	-90(ra) # 80005f10 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	160080e7          	jalr	352(ra) # 800030d2 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	804080e7          	jalr	-2044(ra) # 8000377e <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	7a2080e7          	jalr	1954(ra) # 80004724 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	08e080e7          	jalr	142(ra) # 80006018 <virtio_disk_init>
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
    80001a1a:	e3a7a783          	lw	a5,-454(a5) # 80008850 <first.1719>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	f16080e7          	jalr	-234(ra) # 80002936 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	e207a023          	sw	zero,-480(a5) # 80008850 <first.1719>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	cc4080e7          	jalr	-828(ra) # 800036fe <fsinit>
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
    80001d00:	424080e7          	jalr	1060(ra) # 80004120 <namei>
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
    80001e1e:	99c080e7          	jalr	-1636(ra) # 800047b6 <filedup>
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
    80001e40:	b00080e7          	jalr	-1280(ra) # 8000393c <idup>
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
    80001f2c:	964080e7          	jalr	-1692(ra) # 8000288c <swtch>
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
    80001fd0:	8c0080e7          	jalr	-1856(ra) # 8000288c <swtch>
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
    800021e2:	62a080e7          	jalr	1578(ra) # 80004808 <fileclose>
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
    800021fa:	146080e7          	jalr	326(ra) # 8000433c <begin_op>
  iput(p->cwd);
    800021fe:	1509b503          	ld	a0,336(s3)
    80002202:	00002097          	auipc	ra,0x2
    80002206:	932080e7          	jalr	-1742(ra) # 80003b34 <iput>
  end_op();
    8000220a:	00002097          	auipc	ra,0x2
    8000220e:	1b2080e7          	jalr	434(ra) # 800043bc <end_op>
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

00000000800022e6 <forkn>:
  if (n < 1 || n > MAX_CHILDREN) {
    800022e6:	fff5071b          	addiw	a4,a0,-1
    800022ea:	47bd                	li	a5,15
    800022ec:	0ae7e363          	bltu	a5,a4,80002392 <forkn+0xac>
int forkn(int n, uint64 pids){
    800022f0:	7119                	addi	sp,sp,-128
    800022f2:	fc86                	sd	ra,120(sp)
    800022f4:	f8a2                	sd	s0,112(sp)
    800022f6:	f4a6                	sd	s1,104(sp)
    800022f8:	f0ca                	sd	s2,96(sp)
    800022fa:	ecce                	sd	s3,88(sp)
    800022fc:	e8d2                	sd	s4,80(sp)
    800022fe:	e4d6                	sd	s5,72(sp)
    80002300:	e0da                	sd	s6,64(sp)
    80002302:	0100                	addi	s0,sp,128
    80002304:	8aaa                	mv	s5,a0
    80002306:	8b2e                	mv	s6,a1
    80002308:	f8040a13          	addi	s4,s0,-128
  if (n < 1 || n > MAX_CHILDREN) {
    8000230c:	8952                	mv	s2,s4
int created = 0;
    8000230e:	4481                	li	s1,0
    80002310:	0004899b          	sext.w	s3,s1
    int pid = fork();
    80002314:	00000097          	auipc	ra,0x0
    80002318:	a68080e7          	jalr	-1432(ra) # 80001d7c <fork>
    if (pid < 0) {
    8000231c:	04054363          	bltz	a0,80002362 <forkn+0x7c>
    } else if (pid == 0) {
    80002320:	c535                	beqz	a0,8000238c <forkn+0xa6>
    child_pids[created++] = pid;
    80002322:	2485                	addiw	s1,s1,1
    80002324:	00a92023          	sw	a0,0(s2)
for (int i = 0; i < n; i++) {
    80002328:	0911                	addi	s2,s2,4
    8000232a:	fe9a93e3          	bne	s5,s1,80002310 <forkn+0x2a>
if (copyout(myproc()->pagetable, pids, (char *)child_pids, sizeof(int) * n) < 0) {
    8000232e:	fffff097          	auipc	ra,0xfffff
    80002332:	698080e7          	jalr	1688(ra) # 800019c6 <myproc>
    80002336:	00249693          	slli	a3,s1,0x2
    8000233a:	f8040613          	addi	a2,s0,-128
    8000233e:	85da                	mv	a1,s6
    80002340:	6928                	ld	a0,80(a0)
    80002342:	fffff097          	auipc	ra,0xfffff
    80002346:	342080e7          	jalr	834(ra) # 80001684 <copyout>
    8000234a:	41f5551b          	sraiw	a0,a0,0x1f
}
    8000234e:	70e6                	ld	ra,120(sp)
    80002350:	7446                	ld	s0,112(sp)
    80002352:	74a6                	ld	s1,104(sp)
    80002354:	7906                	ld	s2,96(sp)
    80002356:	69e6                	ld	s3,88(sp)
    80002358:	6a46                	ld	s4,80(sp)
    8000235a:	6aa6                	ld	s5,72(sp)
    8000235c:	6b06                	ld	s6,64(sp)
    8000235e:	6109                	addi	sp,sp,128
    80002360:	8082                	ret
        for (int j = 0; j < created; j++) {
    80002362:	02905a63          	blez	s1,80002396 <forkn+0xb0>
    80002366:	fff9849b          	addiw	s1,s3,-1
    8000236a:	1482                	slli	s1,s1,0x20
    8000236c:	9081                	srli	s1,s1,0x20
    8000236e:	048a                	slli	s1,s1,0x2
    80002370:	004a0793          	addi	a5,s4,4
    80002374:	94be                	add	s1,s1,a5
            kill(child_pids[j]);
    80002376:	000a2503          	lw	a0,0(s4)
    8000237a:	00000097          	auipc	ra,0x0
    8000237e:	efa080e7          	jalr	-262(ra) # 80002274 <kill>
        for (int j = 0; j < created; j++) {
    80002382:	0a11                	addi	s4,s4,4
    80002384:	fe9a19e3          	bne	s4,s1,80002376 <forkn+0x90>
        return -1;  // Indicate failure
    80002388:	557d                	li	a0,-1
    8000238a:	b7d1                	j	8000234e <forkn+0x68>
        return i + 1;  // Child returns its index (1-based)
    8000238c:	0014851b          	addiw	a0,s1,1
    80002390:	bf7d                	j	8000234e <forkn+0x68>
    return -1; // Restrict range of child processes
    80002392:	557d                	li	a0,-1
}
    80002394:	8082                	ret
        return -1;  // Indicate failure
    80002396:	557d                	li	a0,-1
    80002398:	bf5d                	j	8000234e <forkn+0x68>

000000008000239a <setkilled>:

void
setkilled(struct proc *p)
{
    8000239a:	1101                	addi	sp,sp,-32
    8000239c:	ec06                	sd	ra,24(sp)
    8000239e:	e822                	sd	s0,16(sp)
    800023a0:	e426                	sd	s1,8(sp)
    800023a2:	1000                	addi	s0,sp,32
    800023a4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023a6:	fffff097          	auipc	ra,0xfffff
    800023aa:	844080e7          	jalr	-1980(ra) # 80000bea <acquire>
  p->killed = 1;
    800023ae:	4785                	li	a5,1
    800023b0:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	8ea080e7          	jalr	-1814(ra) # 80000c9e <release>
}
    800023bc:	60e2                	ld	ra,24(sp)
    800023be:	6442                	ld	s0,16(sp)
    800023c0:	64a2                	ld	s1,8(sp)
    800023c2:	6105                	addi	sp,sp,32
    800023c4:	8082                	ret

00000000800023c6 <killed>:

int
killed(struct proc *p)
{
    800023c6:	1101                	addi	sp,sp,-32
    800023c8:	ec06                	sd	ra,24(sp)
    800023ca:	e822                	sd	s0,16(sp)
    800023cc:	e426                	sd	s1,8(sp)
    800023ce:	e04a                	sd	s2,0(sp)
    800023d0:	1000                	addi	s0,sp,32
    800023d2:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	816080e7          	jalr	-2026(ra) # 80000bea <acquire>
  k = p->killed;
    800023dc:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023e0:	8526                	mv	a0,s1
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	8bc080e7          	jalr	-1860(ra) # 80000c9e <release>
  return k;
}
    800023ea:	854a                	mv	a0,s2
    800023ec:	60e2                	ld	ra,24(sp)
    800023ee:	6442                	ld	s0,16(sp)
    800023f0:	64a2                	ld	s1,8(sp)
    800023f2:	6902                	ld	s2,0(sp)
    800023f4:	6105                	addi	sp,sp,32
    800023f6:	8082                	ret

00000000800023f8 <wait>:
{
    800023f8:	715d                	addi	sp,sp,-80
    800023fa:	e486                	sd	ra,72(sp)
    800023fc:	e0a2                	sd	s0,64(sp)
    800023fe:	fc26                	sd	s1,56(sp)
    80002400:	f84a                	sd	s2,48(sp)
    80002402:	f44e                	sd	s3,40(sp)
    80002404:	f052                	sd	s4,32(sp)
    80002406:	ec56                	sd	s5,24(sp)
    80002408:	e85a                	sd	s6,16(sp)
    8000240a:	e45e                	sd	s7,8(sp)
    8000240c:	e062                	sd	s8,0(sp)
    8000240e:	0880                	addi	s0,sp,80
    80002410:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	5b4080e7          	jalr	1460(ra) # 800019c6 <myproc>
    8000241a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000241c:	0000e517          	auipc	a0,0xe
    80002420:	73c50513          	addi	a0,a0,1852 # 80010b58 <wait_lock>
    80002424:	ffffe097          	auipc	ra,0xffffe
    80002428:	7c6080e7          	jalr	1990(ra) # 80000bea <acquire>
    havekids = 0;
    8000242c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000242e:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002430:	00014997          	auipc	s3,0x14
    80002434:	54098993          	addi	s3,s3,1344 # 80016970 <tickslock>
        havekids = 1;
    80002438:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000243a:	0000ec17          	auipc	s8,0xe
    8000243e:	71ec0c13          	addi	s8,s8,1822 # 80010b58 <wait_lock>
    havekids = 0;
    80002442:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002444:	0000f497          	auipc	s1,0xf
    80002448:	b2c48493          	addi	s1,s1,-1236 # 80010f70 <proc>
    8000244c:	a0bd                	j	800024ba <wait+0xc2>
          pid = pp->pid;
    8000244e:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002452:	000b0e63          	beqz	s6,8000246e <wait+0x76>
    80002456:	4691                	li	a3,4
    80002458:	02c48613          	addi	a2,s1,44
    8000245c:	85da                	mv	a1,s6
    8000245e:	05093503          	ld	a0,80(s2)
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	222080e7          	jalr	546(ra) # 80001684 <copyout>
    8000246a:	02054563          	bltz	a0,80002494 <wait+0x9c>
          freeproc(pp);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	708080e7          	jalr	1800(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	824080e7          	jalr	-2012(ra) # 80000c9e <release>
          release(&wait_lock);
    80002482:	0000e517          	auipc	a0,0xe
    80002486:	6d650513          	addi	a0,a0,1750 # 80010b58 <wait_lock>
    8000248a:	fffff097          	auipc	ra,0xfffff
    8000248e:	814080e7          	jalr	-2028(ra) # 80000c9e <release>
          return pid;
    80002492:	a0b5                	j	800024fe <wait+0x106>
            release(&pp->lock);
    80002494:	8526                	mv	a0,s1
    80002496:	fffff097          	auipc	ra,0xfffff
    8000249a:	808080e7          	jalr	-2040(ra) # 80000c9e <release>
            release(&wait_lock);
    8000249e:	0000e517          	auipc	a0,0xe
    800024a2:	6ba50513          	addi	a0,a0,1722 # 80010b58 <wait_lock>
    800024a6:	ffffe097          	auipc	ra,0xffffe
    800024aa:	7f8080e7          	jalr	2040(ra) # 80000c9e <release>
            return -1;
    800024ae:	59fd                	li	s3,-1
    800024b0:	a0b9                	j	800024fe <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024b2:	16848493          	addi	s1,s1,360
    800024b6:	03348463          	beq	s1,s3,800024de <wait+0xe6>
      if(pp->parent == p){
    800024ba:	7c9c                	ld	a5,56(s1)
    800024bc:	ff279be3          	bne	a5,s2,800024b2 <wait+0xba>
        acquire(&pp->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	728080e7          	jalr	1832(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    800024ca:	4c9c                	lw	a5,24(s1)
    800024cc:	f94781e3          	beq	a5,s4,8000244e <wait+0x56>
        release(&pp->lock);
    800024d0:	8526                	mv	a0,s1
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	7cc080e7          	jalr	1996(ra) # 80000c9e <release>
        havekids = 1;
    800024da:	8756                	mv	a4,s5
    800024dc:	bfd9                	j	800024b2 <wait+0xba>
    if(!havekids || killed(p)){
    800024de:	c719                	beqz	a4,800024ec <wait+0xf4>
    800024e0:	854a                	mv	a0,s2
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	ee4080e7          	jalr	-284(ra) # 800023c6 <killed>
    800024ea:	c51d                	beqz	a0,80002518 <wait+0x120>
      release(&wait_lock);
    800024ec:	0000e517          	auipc	a0,0xe
    800024f0:	66c50513          	addi	a0,a0,1644 # 80010b58 <wait_lock>
    800024f4:	ffffe097          	auipc	ra,0xffffe
    800024f8:	7aa080e7          	jalr	1962(ra) # 80000c9e <release>
      return -1;
    800024fc:	59fd                	li	s3,-1
}
    800024fe:	854e                	mv	a0,s3
    80002500:	60a6                	ld	ra,72(sp)
    80002502:	6406                	ld	s0,64(sp)
    80002504:	74e2                	ld	s1,56(sp)
    80002506:	7942                	ld	s2,48(sp)
    80002508:	79a2                	ld	s3,40(sp)
    8000250a:	7a02                	ld	s4,32(sp)
    8000250c:	6ae2                	ld	s5,24(sp)
    8000250e:	6b42                	ld	s6,16(sp)
    80002510:	6ba2                	ld	s7,8(sp)
    80002512:	6c02                	ld	s8,0(sp)
    80002514:	6161                	addi	sp,sp,80
    80002516:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002518:	85e2                	mv	a1,s8
    8000251a:	854a                	mv	a0,s2
    8000251c:	00000097          	auipc	ra,0x0
    80002520:	b4e080e7          	jalr	-1202(ra) # 8000206a <sleep>
    havekids = 0;
    80002524:	bf39                	j	80002442 <wait+0x4a>

0000000080002526 <waitall>:
{
    80002526:	7149                	addi	sp,sp,-368
    80002528:	f686                	sd	ra,360(sp)
    8000252a:	f2a2                	sd	s0,352(sp)
    8000252c:	eea6                	sd	s1,344(sp)
    8000252e:	eaca                	sd	s2,336(sp)
    80002530:	e6ce                	sd	s3,328(sp)
    80002532:	e2d2                	sd	s4,320(sp)
    80002534:	fe56                	sd	s5,312(sp)
    80002536:	fa5a                	sd	s6,304(sp)
    80002538:	f65e                	sd	s7,296(sp)
    8000253a:	f262                	sd	s8,288(sp)
    8000253c:	ee66                	sd	s9,280(sp)
    8000253e:	1a80                	addi	s0,sp,368
    80002540:	8baa                	mv	s7,a0
    80002542:	8c2e                	mv	s8,a1
  struct proc *p = myproc();
    80002544:	fffff097          	auipc	ra,0xfffff
    80002548:	482080e7          	jalr	1154(ra) # 800019c6 <myproc>
  int count = 0;
    8000254c:	f8042e23          	sw	zero,-100(s0)
  if(n == 0 || statuses == 0)
    80002550:	180b8263          	beqz	s7,800026d4 <waitall+0x1ae>
    80002554:	84aa                	mv	s1,a0
    80002556:	180c0163          	beqz	s8,800026d8 <waitall+0x1b2>
  acquire(&wait_lock);
    8000255a:	0000e517          	auipc	a0,0xe
    8000255e:	5fe50513          	addi	a0,a0,1534 # 80010b58 <wait_lock>
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	688080e7          	jalr	1672(ra) # 80000bea <acquire>
    count = 0;
    8000256a:	4a81                	li	s5,0
        if(pp->state == ZOMBIE){
    8000256c:	4995                	li	s3,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000256e:	00014917          	auipc	s2,0x14
    80002572:	40290913          	addi	s2,s2,1026 # 80016970 <tickslock>
          count++;
    80002576:	4a05                	li	s4,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002578:	0000eb17          	auipc	s6,0xe
    8000257c:	5e0b0b13          	addi	s6,s6,1504 # 80010b58 <wait_lock>
    80002580:	a0f1                	j	8000264c <waitall+0x126>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002582:	16878793          	addi	a5,a5,360
    80002586:	03278463          	beq	a5,s2,800025ae <waitall+0x88>
      if(pp->parent == p){
    8000258a:	7f98                	ld	a4,56(a5)
    8000258c:	fe971be3          	bne	a4,s1,80002582 <waitall+0x5c>
        if(pp->state == ZOMBIE){
    80002590:	4f98                	lw	a4,24(a5)
    80002592:	09371363          	bne	a4,s3,80002618 <waitall+0xf2>
          local_statuses[count] = pp->xstate;
    80002596:	00269713          	slli	a4,a3,0x2
    8000259a:	fa040613          	addi	a2,s0,-96
    8000259e:	9732                	add	a4,a4,a2
    800025a0:	57d0                	lw	a2,44(a5)
    800025a2:	eec72c23          	sw	a2,-264(a4)
          count++;
    800025a6:	2685                	addiw	a3,a3,1
    800025a8:	8652                	mv	a2,s4
        havekids = 1;
    800025aa:	8cd2                	mv	s9,s4
    800025ac:	bfd9                	j	80002582 <waitall+0x5c>
    800025ae:	c219                	beqz	a2,800025b4 <waitall+0x8e>
    800025b0:	f8d42e23          	sw	a3,-100(s0)
    if(!havekids){
    800025b4:	000c8763          	beqz	s9,800025c2 <waitall+0x9c>
        havekids = 1;
    800025b8:	0000f797          	auipc	a5,0xf
    800025bc:	9b878793          	addi	a5,a5,-1608 # 80010f70 <proc>
    800025c0:	a0a5                	j	80002628 <waitall+0x102>
      if(copyout(p->pagetable, (uint64)n, (char *)&count, sizeof(int)) < 0){
    800025c2:	4691                	li	a3,4
    800025c4:	f9c40613          	addi	a2,s0,-100
    800025c8:	85de                	mv	a1,s7
    800025ca:	68a8                	ld	a0,80(s1)
    800025cc:	fffff097          	auipc	ra,0xfffff
    800025d0:	0b8080e7          	jalr	184(ra) # 80001684 <copyout>
    800025d4:	02054863          	bltz	a0,80002604 <waitall+0xde>
      release(&wait_lock);
    800025d8:	0000e517          	auipc	a0,0xe
    800025dc:	58050513          	addi	a0,a0,1408 # 80010b58 <wait_lock>
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	6be080e7          	jalr	1726(ra) # 80000c9e <release>
}
    800025e8:	8566                	mv	a0,s9
    800025ea:	70b6                	ld	ra,360(sp)
    800025ec:	7416                	ld	s0,352(sp)
    800025ee:	64f6                	ld	s1,344(sp)
    800025f0:	6956                	ld	s2,336(sp)
    800025f2:	69b6                	ld	s3,328(sp)
    800025f4:	6a16                	ld	s4,320(sp)
    800025f6:	7af2                	ld	s5,312(sp)
    800025f8:	7b52                	ld	s6,304(sp)
    800025fa:	7bb2                	ld	s7,296(sp)
    800025fc:	7c12                	ld	s8,288(sp)
    800025fe:	6cf2                	ld	s9,280(sp)
    80002600:	6175                	addi	sp,sp,368
    80002602:	8082                	ret
        release(&wait_lock);
    80002604:	0000e517          	auipc	a0,0xe
    80002608:	55450513          	addi	a0,a0,1364 # 80010b58 <wait_lock>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	692080e7          	jalr	1682(ra) # 80000c9e <release>
        return -1;
    80002614:	5cfd                	li	s9,-1
    80002616:	bfc9                	j	800025e8 <waitall+0xc2>
    80002618:	d245                	beqz	a2,800025b8 <waitall+0x92>
    8000261a:	f8d42e23          	sw	a3,-100(s0)
    8000261e:	bf69                	j	800025b8 <waitall+0x92>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002620:	16878793          	addi	a5,a5,360
    80002624:	0b278c63          	beq	a5,s2,800026dc <waitall+0x1b6>
      if(pp->parent == p && pp->state != ZOMBIE){
    80002628:	7f98                	ld	a4,56(a5)
    8000262a:	fe971be3          	bne	a4,s1,80002620 <waitall+0xfa>
    8000262e:	4f98                	lw	a4,24(a5)
    80002630:	ff3708e3          	beq	a4,s3,80002620 <waitall+0xfa>
    if(killed(p)){
    80002634:	8526                	mv	a0,s1
    80002636:	00000097          	auipc	ra,0x0
    8000263a:	d90080e7          	jalr	-624(ra) # 800023c6 <killed>
    8000263e:	e149                	bnez	a0,800026c0 <waitall+0x19a>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002640:	85da                	mv	a1,s6
    80002642:	8526                	mv	a0,s1
    80002644:	00000097          	auipc	ra,0x0
    80002648:	a26080e7          	jalr	-1498(ra) # 8000206a <sleep>
    count = 0;
    8000264c:	f8042e23          	sw	zero,-100(s0)
    80002650:	8656                	mv	a2,s5
    80002652:	86d6                	mv	a3,s5
    havekids = 0;
    80002654:	8cd6                	mv	s9,s5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002656:	0000f797          	auipc	a5,0xf
    8000265a:	91a78793          	addi	a5,a5,-1766 # 80010f70 <proc>
    8000265e:	b735                	j	8000258a <waitall+0x64>
        release(&wait_lock);
    80002660:	0000e517          	auipc	a0,0xe
    80002664:	4f850513          	addi	a0,a0,1272 # 80010b58 <wait_lock>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	636080e7          	jalr	1590(ra) # 80000c9e <release>
        return -1;
    80002670:	5cfd                	li	s9,-1
    80002672:	bf9d                	j	800025e8 <waitall+0xc2>
      for(pp = proc; pp < &proc[NPROC]; pp++){
    80002674:	16890913          	addi	s2,s2,360
    80002678:	03390a63          	beq	s2,s3,800026ac <waitall+0x186>
        if(pp->parent == p && pp->state == ZOMBIE){
    8000267c:	03893783          	ld	a5,56(s2)
    80002680:	fe979ae3          	bne	a5,s1,80002674 <waitall+0x14e>
    80002684:	01892783          	lw	a5,24(s2)
    80002688:	ff4796e3          	bne	a5,s4,80002674 <waitall+0x14e>
          acquire(&pp->lock);
    8000268c:	854a                	mv	a0,s2
    8000268e:	ffffe097          	auipc	ra,0xffffe
    80002692:	55c080e7          	jalr	1372(ra) # 80000bea <acquire>
          freeproc(pp);
    80002696:	854a                	mv	a0,s2
    80002698:	fffff097          	auipc	ra,0xfffff
    8000269c:	4e0080e7          	jalr	1248(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    800026a0:	854a                	mv	a0,s2
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	5fc080e7          	jalr	1532(ra) # 80000c9e <release>
    800026aa:	b7e9                	j	80002674 <waitall+0x14e>
      release(&wait_lock);
    800026ac:	0000e517          	auipc	a0,0xe
    800026b0:	4ac50513          	addi	a0,a0,1196 # 80010b58 <wait_lock>
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	5ea080e7          	jalr	1514(ra) # 80000c9e <release>
      return 0;
    800026bc:	4c81                	li	s9,0
    800026be:	b72d                	j	800025e8 <waitall+0xc2>
      release(&wait_lock);
    800026c0:	0000e517          	auipc	a0,0xe
    800026c4:	49850513          	addi	a0,a0,1176 # 80010b58 <wait_lock>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	5d6080e7          	jalr	1494(ra) # 80000c9e <release>
      return -1;
    800026d0:	5cfd                	li	s9,-1
    800026d2:	bf19                	j	800025e8 <waitall+0xc2>
    return -1;
    800026d4:	5cfd                	li	s9,-1
    800026d6:	bf09                	j	800025e8 <waitall+0xc2>
    800026d8:	5cfd                	li	s9,-1
    800026da:	b739                	j	800025e8 <waitall+0xc2>
      if(copyout(p->pagetable, (uint64)n, (char *)&count, sizeof(int)) < 0){
    800026dc:	4691                	li	a3,4
    800026de:	f9c40613          	addi	a2,s0,-100
    800026e2:	85de                	mv	a1,s7
    800026e4:	68a8                	ld	a0,80(s1)
    800026e6:	fffff097          	auipc	ra,0xfffff
    800026ea:	f9e080e7          	jalr	-98(ra) # 80001684 <copyout>
    800026ee:	f60549e3          	bltz	a0,80002660 <waitall+0x13a>
      if(copyout(p->pagetable, (uint64)statuses, (char *)local_statuses, 
    800026f2:	f9c42683          	lw	a3,-100(s0)
    800026f6:	068a                	slli	a3,a3,0x2
    800026f8:	e9840613          	addi	a2,s0,-360
    800026fc:	85e2                	mv	a1,s8
    800026fe:	68a8                	ld	a0,80(s1)
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	f84080e7          	jalr	-124(ra) # 80001684 <copyout>
      for(pp = proc; pp < &proc[NPROC]; pp++){
    80002708:	0000f917          	auipc	s2,0xf
    8000270c:	86890913          	addi	s2,s2,-1944 # 80010f70 <proc>
        if(pp->parent == p && pp->state == ZOMBIE){
    80002710:	4a15                	li	s4,5
      for(pp = proc; pp < &proc[NPROC]; pp++){
    80002712:	00014997          	auipc	s3,0x14
    80002716:	25e98993          	addi	s3,s3,606 # 80016970 <tickslock>
      if(copyout(p->pagetable, (uint64)statuses, (char *)local_statuses, 
    8000271a:	f60551e3          	bgez	a0,8000267c <waitall+0x156>
        release(&wait_lock);
    8000271e:	0000e517          	auipc	a0,0xe
    80002722:	43a50513          	addi	a0,a0,1082 # 80010b58 <wait_lock>
    80002726:	ffffe097          	auipc	ra,0xffffe
    8000272a:	578080e7          	jalr	1400(ra) # 80000c9e <release>
        return -1;
    8000272e:	5cfd                	li	s9,-1
    80002730:	bd65                	j	800025e8 <waitall+0xc2>

0000000080002732 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002732:	7179                	addi	sp,sp,-48
    80002734:	f406                	sd	ra,40(sp)
    80002736:	f022                	sd	s0,32(sp)
    80002738:	ec26                	sd	s1,24(sp)
    8000273a:	e84a                	sd	s2,16(sp)
    8000273c:	e44e                	sd	s3,8(sp)
    8000273e:	e052                	sd	s4,0(sp)
    80002740:	1800                	addi	s0,sp,48
    80002742:	84aa                	mv	s1,a0
    80002744:	892e                	mv	s2,a1
    80002746:	89b2                	mv	s3,a2
    80002748:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000274a:	fffff097          	auipc	ra,0xfffff
    8000274e:	27c080e7          	jalr	636(ra) # 800019c6 <myproc>
  if(user_dst){
    80002752:	c08d                	beqz	s1,80002774 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002754:	86d2                	mv	a3,s4
    80002756:	864e                	mv	a2,s3
    80002758:	85ca                	mv	a1,s2
    8000275a:	6928                	ld	a0,80(a0)
    8000275c:	fffff097          	auipc	ra,0xfffff
    80002760:	f28080e7          	jalr	-216(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002764:	70a2                	ld	ra,40(sp)
    80002766:	7402                	ld	s0,32(sp)
    80002768:	64e2                	ld	s1,24(sp)
    8000276a:	6942                	ld	s2,16(sp)
    8000276c:	69a2                	ld	s3,8(sp)
    8000276e:	6a02                	ld	s4,0(sp)
    80002770:	6145                	addi	sp,sp,48
    80002772:	8082                	ret
    memmove((char *)dst, src, len);
    80002774:	000a061b          	sext.w	a2,s4
    80002778:	85ce                	mv	a1,s3
    8000277a:	854a                	mv	a0,s2
    8000277c:	ffffe097          	auipc	ra,0xffffe
    80002780:	5ca080e7          	jalr	1482(ra) # 80000d46 <memmove>
    return 0;
    80002784:	8526                	mv	a0,s1
    80002786:	bff9                	j	80002764 <either_copyout+0x32>

0000000080002788 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002788:	7179                	addi	sp,sp,-48
    8000278a:	f406                	sd	ra,40(sp)
    8000278c:	f022                	sd	s0,32(sp)
    8000278e:	ec26                	sd	s1,24(sp)
    80002790:	e84a                	sd	s2,16(sp)
    80002792:	e44e                	sd	s3,8(sp)
    80002794:	e052                	sd	s4,0(sp)
    80002796:	1800                	addi	s0,sp,48
    80002798:	892a                	mv	s2,a0
    8000279a:	84ae                	mv	s1,a1
    8000279c:	89b2                	mv	s3,a2
    8000279e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	226080e7          	jalr	550(ra) # 800019c6 <myproc>
  if(user_src){
    800027a8:	c08d                	beqz	s1,800027ca <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800027aa:	86d2                	mv	a3,s4
    800027ac:	864e                	mv	a2,s3
    800027ae:	85ca                	mv	a1,s2
    800027b0:	6928                	ld	a0,80(a0)
    800027b2:	fffff097          	auipc	ra,0xfffff
    800027b6:	f5e080e7          	jalr	-162(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800027ba:	70a2                	ld	ra,40(sp)
    800027bc:	7402                	ld	s0,32(sp)
    800027be:	64e2                	ld	s1,24(sp)
    800027c0:	6942                	ld	s2,16(sp)
    800027c2:	69a2                	ld	s3,8(sp)
    800027c4:	6a02                	ld	s4,0(sp)
    800027c6:	6145                	addi	sp,sp,48
    800027c8:	8082                	ret
    memmove(dst, (char*)src, len);
    800027ca:	000a061b          	sext.w	a2,s4
    800027ce:	85ce                	mv	a1,s3
    800027d0:	854a                	mv	a0,s2
    800027d2:	ffffe097          	auipc	ra,0xffffe
    800027d6:	574080e7          	jalr	1396(ra) # 80000d46 <memmove>
    return 0;
    800027da:	8526                	mv	a0,s1
    800027dc:	bff9                	j	800027ba <either_copyin+0x32>

00000000800027de <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800027de:	715d                	addi	sp,sp,-80
    800027e0:	e486                	sd	ra,72(sp)
    800027e2:	e0a2                	sd	s0,64(sp)
    800027e4:	fc26                	sd	s1,56(sp)
    800027e6:	f84a                	sd	s2,48(sp)
    800027e8:	f44e                	sd	s3,40(sp)
    800027ea:	f052                	sd	s4,32(sp)
    800027ec:	ec56                	sd	s5,24(sp)
    800027ee:	e85a                	sd	s6,16(sp)
    800027f0:	e45e                	sd	s7,8(sp)
    800027f2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800027f4:	00006517          	auipc	a0,0x6
    800027f8:	8d450513          	addi	a0,a0,-1836 # 800080c8 <digits+0x88>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	d92080e7          	jalr	-622(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002804:	0000f497          	auipc	s1,0xf
    80002808:	8c448493          	addi	s1,s1,-1852 # 800110c8 <proc+0x158>
    8000280c:	00014917          	auipc	s2,0x14
    80002810:	2bc90913          	addi	s2,s2,700 # 80016ac8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002814:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002816:	00006997          	auipc	s3,0x6
    8000281a:	a6a98993          	addi	s3,s3,-1430 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    8000281e:	00006a97          	auipc	s5,0x6
    80002822:	a6aa8a93          	addi	s5,s5,-1430 # 80008288 <digits+0x248>
    printf("\n");
    80002826:	00006a17          	auipc	s4,0x6
    8000282a:	8a2a0a13          	addi	s4,s4,-1886 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000282e:	00006b97          	auipc	s7,0x6
    80002832:	a9ab8b93          	addi	s7,s7,-1382 # 800082c8 <states.1763>
    80002836:	a00d                	j	80002858 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002838:	ed86a583          	lw	a1,-296(a3)
    8000283c:	8556                	mv	a0,s5
    8000283e:	ffffe097          	auipc	ra,0xffffe
    80002842:	d50080e7          	jalr	-688(ra) # 8000058e <printf>
    printf("\n");
    80002846:	8552                	mv	a0,s4
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d46080e7          	jalr	-698(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002850:	16848493          	addi	s1,s1,360
    80002854:	03248163          	beq	s1,s2,80002876 <procdump+0x98>
    if(p->state == UNUSED)
    80002858:	86a6                	mv	a3,s1
    8000285a:	ec04a783          	lw	a5,-320(s1)
    8000285e:	dbed                	beqz	a5,80002850 <procdump+0x72>
      state = "???";
    80002860:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002862:	fcfb6be3          	bltu	s6,a5,80002838 <procdump+0x5a>
    80002866:	1782                	slli	a5,a5,0x20
    80002868:	9381                	srli	a5,a5,0x20
    8000286a:	078e                	slli	a5,a5,0x3
    8000286c:	97de                	add	a5,a5,s7
    8000286e:	6390                	ld	a2,0(a5)
    80002870:	f661                	bnez	a2,80002838 <procdump+0x5a>
      state = "???";
    80002872:	864e                	mv	a2,s3
    80002874:	b7d1                	j	80002838 <procdump+0x5a>
  }
}
    80002876:	60a6                	ld	ra,72(sp)
    80002878:	6406                	ld	s0,64(sp)
    8000287a:	74e2                	ld	s1,56(sp)
    8000287c:	7942                	ld	s2,48(sp)
    8000287e:	79a2                	ld	s3,40(sp)
    80002880:	7a02                	ld	s4,32(sp)
    80002882:	6ae2                	ld	s5,24(sp)
    80002884:	6b42                	ld	s6,16(sp)
    80002886:	6ba2                	ld	s7,8(sp)
    80002888:	6161                	addi	sp,sp,80
    8000288a:	8082                	ret

000000008000288c <swtch>:
    8000288c:	00153023          	sd	ra,0(a0)
    80002890:	00253423          	sd	sp,8(a0)
    80002894:	e900                	sd	s0,16(a0)
    80002896:	ed04                	sd	s1,24(a0)
    80002898:	03253023          	sd	s2,32(a0)
    8000289c:	03353423          	sd	s3,40(a0)
    800028a0:	03453823          	sd	s4,48(a0)
    800028a4:	03553c23          	sd	s5,56(a0)
    800028a8:	05653023          	sd	s6,64(a0)
    800028ac:	05753423          	sd	s7,72(a0)
    800028b0:	05853823          	sd	s8,80(a0)
    800028b4:	05953c23          	sd	s9,88(a0)
    800028b8:	07a53023          	sd	s10,96(a0)
    800028bc:	07b53423          	sd	s11,104(a0)
    800028c0:	0005b083          	ld	ra,0(a1)
    800028c4:	0085b103          	ld	sp,8(a1)
    800028c8:	6980                	ld	s0,16(a1)
    800028ca:	6d84                	ld	s1,24(a1)
    800028cc:	0205b903          	ld	s2,32(a1)
    800028d0:	0285b983          	ld	s3,40(a1)
    800028d4:	0305ba03          	ld	s4,48(a1)
    800028d8:	0385ba83          	ld	s5,56(a1)
    800028dc:	0405bb03          	ld	s6,64(a1)
    800028e0:	0485bb83          	ld	s7,72(a1)
    800028e4:	0505bc03          	ld	s8,80(a1)
    800028e8:	0585bc83          	ld	s9,88(a1)
    800028ec:	0605bd03          	ld	s10,96(a1)
    800028f0:	0685bd83          	ld	s11,104(a1)
    800028f4:	8082                	ret

00000000800028f6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800028f6:	1141                	addi	sp,sp,-16
    800028f8:	e406                	sd	ra,8(sp)
    800028fa:	e022                	sd	s0,0(sp)
    800028fc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800028fe:	00006597          	auipc	a1,0x6
    80002902:	9fa58593          	addi	a1,a1,-1542 # 800082f8 <states.1763+0x30>
    80002906:	00014517          	auipc	a0,0x14
    8000290a:	06a50513          	addi	a0,a0,106 # 80016970 <tickslock>
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	24c080e7          	jalr	588(ra) # 80000b5a <initlock>
}
    80002916:	60a2                	ld	ra,8(sp)
    80002918:	6402                	ld	s0,0(sp)
    8000291a:	0141                	addi	sp,sp,16
    8000291c:	8082                	ret

000000008000291e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000291e:	1141                	addi	sp,sp,-16
    80002920:	e422                	sd	s0,8(sp)
    80002922:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002924:	00003797          	auipc	a5,0x3
    80002928:	51c78793          	addi	a5,a5,1308 # 80005e40 <kernelvec>
    8000292c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002930:	6422                	ld	s0,8(sp)
    80002932:	0141                	addi	sp,sp,16
    80002934:	8082                	ret

0000000080002936 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002936:	1141                	addi	sp,sp,-16
    80002938:	e406                	sd	ra,8(sp)
    8000293a:	e022                	sd	s0,0(sp)
    8000293c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000293e:	fffff097          	auipc	ra,0xfffff
    80002942:	088080e7          	jalr	136(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002946:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000294a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000294c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002950:	00004617          	auipc	a2,0x4
    80002954:	6b060613          	addi	a2,a2,1712 # 80007000 <_trampoline>
    80002958:	00004697          	auipc	a3,0x4
    8000295c:	6a868693          	addi	a3,a3,1704 # 80007000 <_trampoline>
    80002960:	8e91                	sub	a3,a3,a2
    80002962:	040007b7          	lui	a5,0x4000
    80002966:	17fd                	addi	a5,a5,-1
    80002968:	07b2                	slli	a5,a5,0xc
    8000296a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000296c:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002970:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002972:	180026f3          	csrr	a3,satp
    80002976:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002978:	6d38                	ld	a4,88(a0)
    8000297a:	6134                	ld	a3,64(a0)
    8000297c:	6585                	lui	a1,0x1
    8000297e:	96ae                	add	a3,a3,a1
    80002980:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002982:	6d38                	ld	a4,88(a0)
    80002984:	00000697          	auipc	a3,0x0
    80002988:	13068693          	addi	a3,a3,304 # 80002ab4 <usertrap>
    8000298c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000298e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002990:	8692                	mv	a3,tp
    80002992:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002994:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002998:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000299c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029a0:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800029a4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029a6:	6f18                	ld	a4,24(a4)
    800029a8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800029ac:	6928                	ld	a0,80(a0)
    800029ae:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800029b0:	00004717          	auipc	a4,0x4
    800029b4:	6ec70713          	addi	a4,a4,1772 # 8000709c <userret>
    800029b8:	8f11                	sub	a4,a4,a2
    800029ba:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800029bc:	577d                	li	a4,-1
    800029be:	177e                	slli	a4,a4,0x3f
    800029c0:	8d59                	or	a0,a0,a4
    800029c2:	9782                	jalr	a5
}
    800029c4:	60a2                	ld	ra,8(sp)
    800029c6:	6402                	ld	s0,0(sp)
    800029c8:	0141                	addi	sp,sp,16
    800029ca:	8082                	ret

00000000800029cc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800029cc:	1101                	addi	sp,sp,-32
    800029ce:	ec06                	sd	ra,24(sp)
    800029d0:	e822                	sd	s0,16(sp)
    800029d2:	e426                	sd	s1,8(sp)
    800029d4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800029d6:	00014497          	auipc	s1,0x14
    800029da:	f9a48493          	addi	s1,s1,-102 # 80016970 <tickslock>
    800029de:	8526                	mv	a0,s1
    800029e0:	ffffe097          	auipc	ra,0xffffe
    800029e4:	20a080e7          	jalr	522(ra) # 80000bea <acquire>
  ticks++;
    800029e8:	00006517          	auipc	a0,0x6
    800029ec:	ee850513          	addi	a0,a0,-280 # 800088d0 <ticks>
    800029f0:	411c                	lw	a5,0(a0)
    800029f2:	2785                	addiw	a5,a5,1
    800029f4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800029f6:	fffff097          	auipc	ra,0xfffff
    800029fa:	6d8080e7          	jalr	1752(ra) # 800020ce <wakeup>
  release(&tickslock);
    800029fe:	8526                	mv	a0,s1
    80002a00:	ffffe097          	auipc	ra,0xffffe
    80002a04:	29e080e7          	jalr	670(ra) # 80000c9e <release>
}
    80002a08:	60e2                	ld	ra,24(sp)
    80002a0a:	6442                	ld	s0,16(sp)
    80002a0c:	64a2                	ld	s1,8(sp)
    80002a0e:	6105                	addi	sp,sp,32
    80002a10:	8082                	ret

0000000080002a12 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002a12:	1101                	addi	sp,sp,-32
    80002a14:	ec06                	sd	ra,24(sp)
    80002a16:	e822                	sd	s0,16(sp)
    80002a18:	e426                	sd	s1,8(sp)
    80002a1a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a1c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002a20:	00074d63          	bltz	a4,80002a3a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002a24:	57fd                	li	a5,-1
    80002a26:	17fe                	slli	a5,a5,0x3f
    80002a28:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002a2a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002a2c:	06f70363          	beq	a4,a5,80002a92 <devintr+0x80>
  }
}
    80002a30:	60e2                	ld	ra,24(sp)
    80002a32:	6442                	ld	s0,16(sp)
    80002a34:	64a2                	ld	s1,8(sp)
    80002a36:	6105                	addi	sp,sp,32
    80002a38:	8082                	ret
     (scause & 0xff) == 9){
    80002a3a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002a3e:	46a5                	li	a3,9
    80002a40:	fed792e3          	bne	a5,a3,80002a24 <devintr+0x12>
    int irq = plic_claim();
    80002a44:	00003097          	auipc	ra,0x3
    80002a48:	504080e7          	jalr	1284(ra) # 80005f48 <plic_claim>
    80002a4c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002a4e:	47a9                	li	a5,10
    80002a50:	02f50763          	beq	a0,a5,80002a7e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002a54:	4785                	li	a5,1
    80002a56:	02f50963          	beq	a0,a5,80002a88 <devintr+0x76>
    return 1;
    80002a5a:	4505                	li	a0,1
    } else if(irq){
    80002a5c:	d8f1                	beqz	s1,80002a30 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002a5e:	85a6                	mv	a1,s1
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	8a050513          	addi	a0,a0,-1888 # 80008300 <states.1763+0x38>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	b26080e7          	jalr	-1242(ra) # 8000058e <printf>
      plic_complete(irq);
    80002a70:	8526                	mv	a0,s1
    80002a72:	00003097          	auipc	ra,0x3
    80002a76:	4fa080e7          	jalr	1274(ra) # 80005f6c <plic_complete>
    return 1;
    80002a7a:	4505                	li	a0,1
    80002a7c:	bf55                	j	80002a30 <devintr+0x1e>
      uartintr();
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	f30080e7          	jalr	-208(ra) # 800009ae <uartintr>
    80002a86:	b7ed                	j	80002a70 <devintr+0x5e>
      virtio_disk_intr();
    80002a88:	00004097          	auipc	ra,0x4
    80002a8c:	a0e080e7          	jalr	-1522(ra) # 80006496 <virtio_disk_intr>
    80002a90:	b7c5                	j	80002a70 <devintr+0x5e>
    if(cpuid() == 0){
    80002a92:	fffff097          	auipc	ra,0xfffff
    80002a96:	f08080e7          	jalr	-248(ra) # 8000199a <cpuid>
    80002a9a:	c901                	beqz	a0,80002aaa <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a9c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002aa0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002aa2:	14479073          	csrw	sip,a5
    return 2;
    80002aa6:	4509                	li	a0,2
    80002aa8:	b761                	j	80002a30 <devintr+0x1e>
      clockintr();
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	f22080e7          	jalr	-222(ra) # 800029cc <clockintr>
    80002ab2:	b7ed                	j	80002a9c <devintr+0x8a>

0000000080002ab4 <usertrap>:
{
    80002ab4:	1101                	addi	sp,sp,-32
    80002ab6:	ec06                	sd	ra,24(sp)
    80002ab8:	e822                	sd	s0,16(sp)
    80002aba:	e426                	sd	s1,8(sp)
    80002abc:	e04a                	sd	s2,0(sp)
    80002abe:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ac0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ac4:	1007f793          	andi	a5,a5,256
    80002ac8:	e3b1                	bnez	a5,80002b0c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002aca:	00003797          	auipc	a5,0x3
    80002ace:	37678793          	addi	a5,a5,886 # 80005e40 <kernelvec>
    80002ad2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	ef0080e7          	jalr	-272(ra) # 800019c6 <myproc>
    80002ade:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ae0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ae2:	14102773          	csrr	a4,sepc
    80002ae6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002aec:	47a1                	li	a5,8
    80002aee:	02f70763          	beq	a4,a5,80002b1c <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002af2:	00000097          	auipc	ra,0x0
    80002af6:	f20080e7          	jalr	-224(ra) # 80002a12 <devintr>
    80002afa:	892a                	mv	s2,a0
    80002afc:	c151                	beqz	a0,80002b80 <usertrap+0xcc>
  if(killed(p))
    80002afe:	8526                	mv	a0,s1
    80002b00:	00000097          	auipc	ra,0x0
    80002b04:	8c6080e7          	jalr	-1850(ra) # 800023c6 <killed>
    80002b08:	c929                	beqz	a0,80002b5a <usertrap+0xa6>
    80002b0a:	a099                	j	80002b50 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b0c:	00006517          	auipc	a0,0x6
    80002b10:	81450513          	addi	a0,a0,-2028 # 80008320 <states.1763+0x58>
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	a30080e7          	jalr	-1488(ra) # 80000544 <panic>
    if(killed(p))
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	8aa080e7          	jalr	-1878(ra) # 800023c6 <killed>
    80002b24:	e921                	bnez	a0,80002b74 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002b26:	6cb8                	ld	a4,88(s1)
    80002b28:	6f1c                	ld	a5,24(a4)
    80002b2a:	0791                	addi	a5,a5,4
    80002b2c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002b32:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b36:	10079073          	csrw	sstatus,a5
    syscall();
    80002b3a:	00000097          	auipc	ra,0x0
    80002b3e:	2d4080e7          	jalr	724(ra) # 80002e0e <syscall>
  if(killed(p))
    80002b42:	8526                	mv	a0,s1
    80002b44:	00000097          	auipc	ra,0x0
    80002b48:	882080e7          	jalr	-1918(ra) # 800023c6 <killed>
    80002b4c:	c911                	beqz	a0,80002b60 <usertrap+0xac>
    80002b4e:	4901                	li	s2,0
    exit(-1);
    80002b50:	557d                	li	a0,-1
    80002b52:	fffff097          	auipc	ra,0xfffff
    80002b56:	64c080e7          	jalr	1612(ra) # 8000219e <exit>
  if(which_dev == 2)
    80002b5a:	4789                	li	a5,2
    80002b5c:	04f90f63          	beq	s2,a5,80002bba <usertrap+0x106>
  usertrapret();
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	dd6080e7          	jalr	-554(ra) # 80002936 <usertrapret>
}
    80002b68:	60e2                	ld	ra,24(sp)
    80002b6a:	6442                	ld	s0,16(sp)
    80002b6c:	64a2                	ld	s1,8(sp)
    80002b6e:	6902                	ld	s2,0(sp)
    80002b70:	6105                	addi	sp,sp,32
    80002b72:	8082                	ret
      exit(-1);
    80002b74:	557d                	li	a0,-1
    80002b76:	fffff097          	auipc	ra,0xfffff
    80002b7a:	628080e7          	jalr	1576(ra) # 8000219e <exit>
    80002b7e:	b765                	j	80002b26 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b80:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b84:	5890                	lw	a2,48(s1)
    80002b86:	00005517          	auipc	a0,0x5
    80002b8a:	7ba50513          	addi	a0,a0,1978 # 80008340 <states.1763+0x78>
    80002b8e:	ffffe097          	auipc	ra,0xffffe
    80002b92:	a00080e7          	jalr	-1536(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b96:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b9a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b9e:	00005517          	auipc	a0,0x5
    80002ba2:	7d250513          	addi	a0,a0,2002 # 80008370 <states.1763+0xa8>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	9e8080e7          	jalr	-1560(ra) # 8000058e <printf>
    setkilled(p);
    80002bae:	8526                	mv	a0,s1
    80002bb0:	fffff097          	auipc	ra,0xfffff
    80002bb4:	7ea080e7          	jalr	2026(ra) # 8000239a <setkilled>
    80002bb8:	b769                	j	80002b42 <usertrap+0x8e>
    yield();
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	474080e7          	jalr	1140(ra) # 8000202e <yield>
    80002bc2:	bf79                	j	80002b60 <usertrap+0xac>

0000000080002bc4 <kerneltrap>:
{
    80002bc4:	7179                	addi	sp,sp,-48
    80002bc6:	f406                	sd	ra,40(sp)
    80002bc8:	f022                	sd	s0,32(sp)
    80002bca:	ec26                	sd	s1,24(sp)
    80002bcc:	e84a                	sd	s2,16(sp)
    80002bce:	e44e                	sd	s3,8(sp)
    80002bd0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bda:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002bde:	1004f793          	andi	a5,s1,256
    80002be2:	cb85                	beqz	a5,80002c12 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002be4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002be8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002bea:	ef85                	bnez	a5,80002c22 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002bec:	00000097          	auipc	ra,0x0
    80002bf0:	e26080e7          	jalr	-474(ra) # 80002a12 <devintr>
    80002bf4:	cd1d                	beqz	a0,80002c32 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002bf6:	4789                	li	a5,2
    80002bf8:	06f50a63          	beq	a0,a5,80002c6c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bfc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c00:	10049073          	csrw	sstatus,s1
}
    80002c04:	70a2                	ld	ra,40(sp)
    80002c06:	7402                	ld	s0,32(sp)
    80002c08:	64e2                	ld	s1,24(sp)
    80002c0a:	6942                	ld	s2,16(sp)
    80002c0c:	69a2                	ld	s3,8(sp)
    80002c0e:	6145                	addi	sp,sp,48
    80002c10:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	77e50513          	addi	a0,a0,1918 # 80008390 <states.1763+0xc8>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	92a080e7          	jalr	-1750(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002c22:	00005517          	auipc	a0,0x5
    80002c26:	79650513          	addi	a0,a0,1942 # 800083b8 <states.1763+0xf0>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	91a080e7          	jalr	-1766(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002c32:	85ce                	mv	a1,s3
    80002c34:	00005517          	auipc	a0,0x5
    80002c38:	7a450513          	addi	a0,a0,1956 # 800083d8 <states.1763+0x110>
    80002c3c:	ffffe097          	auipc	ra,0xffffe
    80002c40:	952080e7          	jalr	-1710(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c44:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c48:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c4c:	00005517          	auipc	a0,0x5
    80002c50:	79c50513          	addi	a0,a0,1948 # 800083e8 <states.1763+0x120>
    80002c54:	ffffe097          	auipc	ra,0xffffe
    80002c58:	93a080e7          	jalr	-1734(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002c5c:	00005517          	auipc	a0,0x5
    80002c60:	7a450513          	addi	a0,a0,1956 # 80008400 <states.1763+0x138>
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	8e0080e7          	jalr	-1824(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c6c:	fffff097          	auipc	ra,0xfffff
    80002c70:	d5a080e7          	jalr	-678(ra) # 800019c6 <myproc>
    80002c74:	d541                	beqz	a0,80002bfc <kerneltrap+0x38>
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	d50080e7          	jalr	-688(ra) # 800019c6 <myproc>
    80002c7e:	4d18                	lw	a4,24(a0)
    80002c80:	4791                	li	a5,4
    80002c82:	f6f71de3          	bne	a4,a5,80002bfc <kerneltrap+0x38>
    yield();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	3a8080e7          	jalr	936(ra) # 8000202e <yield>
    80002c8e:	b7bd                	j	80002bfc <kerneltrap+0x38>

0000000080002c90 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	e426                	sd	s1,8(sp)
    80002c98:	1000                	addi	s0,sp,32
    80002c9a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c9c:	fffff097          	auipc	ra,0xfffff
    80002ca0:	d2a080e7          	jalr	-726(ra) # 800019c6 <myproc>
  switch (n) {
    80002ca4:	4795                	li	a5,5
    80002ca6:	0497e163          	bltu	a5,s1,80002ce8 <argraw+0x58>
    80002caa:	048a                	slli	s1,s1,0x2
    80002cac:	00005717          	auipc	a4,0x5
    80002cb0:	78c70713          	addi	a4,a4,1932 # 80008438 <states.1763+0x170>
    80002cb4:	94ba                	add	s1,s1,a4
    80002cb6:	409c                	lw	a5,0(s1)
    80002cb8:	97ba                	add	a5,a5,a4
    80002cba:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002cbc:	6d3c                	ld	a5,88(a0)
    80002cbe:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002cc0:	60e2                	ld	ra,24(sp)
    80002cc2:	6442                	ld	s0,16(sp)
    80002cc4:	64a2                	ld	s1,8(sp)
    80002cc6:	6105                	addi	sp,sp,32
    80002cc8:	8082                	ret
    return p->trapframe->a1;
    80002cca:	6d3c                	ld	a5,88(a0)
    80002ccc:	7fa8                	ld	a0,120(a5)
    80002cce:	bfcd                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a2;
    80002cd0:	6d3c                	ld	a5,88(a0)
    80002cd2:	63c8                	ld	a0,128(a5)
    80002cd4:	b7f5                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a3;
    80002cd6:	6d3c                	ld	a5,88(a0)
    80002cd8:	67c8                	ld	a0,136(a5)
    80002cda:	b7dd                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a4;
    80002cdc:	6d3c                	ld	a5,88(a0)
    80002cde:	6bc8                	ld	a0,144(a5)
    80002ce0:	b7c5                	j	80002cc0 <argraw+0x30>
    return p->trapframe->a5;
    80002ce2:	6d3c                	ld	a5,88(a0)
    80002ce4:	6fc8                	ld	a0,152(a5)
    80002ce6:	bfe9                	j	80002cc0 <argraw+0x30>
  panic("argraw");
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	72850513          	addi	a0,a0,1832 # 80008410 <states.1763+0x148>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	854080e7          	jalr	-1964(ra) # 80000544 <panic>

0000000080002cf8 <fetchaddr>:
{
    80002cf8:	1101                	addi	sp,sp,-32
    80002cfa:	ec06                	sd	ra,24(sp)
    80002cfc:	e822                	sd	s0,16(sp)
    80002cfe:	e426                	sd	s1,8(sp)
    80002d00:	e04a                	sd	s2,0(sp)
    80002d02:	1000                	addi	s0,sp,32
    80002d04:	84aa                	mv	s1,a0
    80002d06:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	cbe080e7          	jalr	-834(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002d10:	653c                	ld	a5,72(a0)
    80002d12:	02f4f863          	bgeu	s1,a5,80002d42 <fetchaddr+0x4a>
    80002d16:	00848713          	addi	a4,s1,8
    80002d1a:	02e7e663          	bltu	a5,a4,80002d46 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002d1e:	46a1                	li	a3,8
    80002d20:	8626                	mv	a2,s1
    80002d22:	85ca                	mv	a1,s2
    80002d24:	6928                	ld	a0,80(a0)
    80002d26:	fffff097          	auipc	ra,0xfffff
    80002d2a:	9ea080e7          	jalr	-1558(ra) # 80001710 <copyin>
    80002d2e:	00a03533          	snez	a0,a0
    80002d32:	40a00533          	neg	a0,a0
}
    80002d36:	60e2                	ld	ra,24(sp)
    80002d38:	6442                	ld	s0,16(sp)
    80002d3a:	64a2                	ld	s1,8(sp)
    80002d3c:	6902                	ld	s2,0(sp)
    80002d3e:	6105                	addi	sp,sp,32
    80002d40:	8082                	ret
    return -1;
    80002d42:	557d                	li	a0,-1
    80002d44:	bfcd                	j	80002d36 <fetchaddr+0x3e>
    80002d46:	557d                	li	a0,-1
    80002d48:	b7fd                	j	80002d36 <fetchaddr+0x3e>

0000000080002d4a <fetchstr>:
{
    80002d4a:	7179                	addi	sp,sp,-48
    80002d4c:	f406                	sd	ra,40(sp)
    80002d4e:	f022                	sd	s0,32(sp)
    80002d50:	ec26                	sd	s1,24(sp)
    80002d52:	e84a                	sd	s2,16(sp)
    80002d54:	e44e                	sd	s3,8(sp)
    80002d56:	1800                	addi	s0,sp,48
    80002d58:	892a                	mv	s2,a0
    80002d5a:	84ae                	mv	s1,a1
    80002d5c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	c68080e7          	jalr	-920(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002d66:	86ce                	mv	a3,s3
    80002d68:	864a                	mv	a2,s2
    80002d6a:	85a6                	mv	a1,s1
    80002d6c:	6928                	ld	a0,80(a0)
    80002d6e:	fffff097          	auipc	ra,0xfffff
    80002d72:	a2e080e7          	jalr	-1490(ra) # 8000179c <copyinstr>
    80002d76:	00054e63          	bltz	a0,80002d92 <fetchstr+0x48>
  return strlen(buf);
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	0ee080e7          	jalr	238(ra) # 80000e6a <strlen>
}
    80002d84:	70a2                	ld	ra,40(sp)
    80002d86:	7402                	ld	s0,32(sp)
    80002d88:	64e2                	ld	s1,24(sp)
    80002d8a:	6942                	ld	s2,16(sp)
    80002d8c:	69a2                	ld	s3,8(sp)
    80002d8e:	6145                	addi	sp,sp,48
    80002d90:	8082                	ret
    return -1;
    80002d92:	557d                	li	a0,-1
    80002d94:	bfc5                	j	80002d84 <fetchstr+0x3a>

0000000080002d96 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d96:	1101                	addi	sp,sp,-32
    80002d98:	ec06                	sd	ra,24(sp)
    80002d9a:	e822                	sd	s0,16(sp)
    80002d9c:	e426                	sd	s1,8(sp)
    80002d9e:	1000                	addi	s0,sp,32
    80002da0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002da2:	00000097          	auipc	ra,0x0
    80002da6:	eee080e7          	jalr	-274(ra) # 80002c90 <argraw>
    80002daa:	c088                	sw	a0,0(s1)
}
    80002dac:	60e2                	ld	ra,24(sp)
    80002dae:	6442                	ld	s0,16(sp)
    80002db0:	64a2                	ld	s1,8(sp)
    80002db2:	6105                	addi	sp,sp,32
    80002db4:	8082                	ret

0000000080002db6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002db6:	1101                	addi	sp,sp,-32
    80002db8:	ec06                	sd	ra,24(sp)
    80002dba:	e822                	sd	s0,16(sp)
    80002dbc:	e426                	sd	s1,8(sp)
    80002dbe:	1000                	addi	s0,sp,32
    80002dc0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002dc2:	00000097          	auipc	ra,0x0
    80002dc6:	ece080e7          	jalr	-306(ra) # 80002c90 <argraw>
    80002dca:	e088                	sd	a0,0(s1)
}
    80002dcc:	60e2                	ld	ra,24(sp)
    80002dce:	6442                	ld	s0,16(sp)
    80002dd0:	64a2                	ld	s1,8(sp)
    80002dd2:	6105                	addi	sp,sp,32
    80002dd4:	8082                	ret

0000000080002dd6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002dd6:	7179                	addi	sp,sp,-48
    80002dd8:	f406                	sd	ra,40(sp)
    80002dda:	f022                	sd	s0,32(sp)
    80002ddc:	ec26                	sd	s1,24(sp)
    80002dde:	e84a                	sd	s2,16(sp)
    80002de0:	1800                	addi	s0,sp,48
    80002de2:	84ae                	mv	s1,a1
    80002de4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002de6:	fd840593          	addi	a1,s0,-40
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	fcc080e7          	jalr	-52(ra) # 80002db6 <argaddr>
  return fetchstr(addr, buf, max);
    80002df2:	864a                	mv	a2,s2
    80002df4:	85a6                	mv	a1,s1
    80002df6:	fd843503          	ld	a0,-40(s0)
    80002dfa:	00000097          	auipc	ra,0x0
    80002dfe:	f50080e7          	jalr	-176(ra) # 80002d4a <fetchstr>
}
    80002e02:	70a2                	ld	ra,40(sp)
    80002e04:	7402                	ld	s0,32(sp)
    80002e06:	64e2                	ld	s1,24(sp)
    80002e08:	6942                	ld	s2,16(sp)
    80002e0a:	6145                	addi	sp,sp,48
    80002e0c:	8082                	ret

0000000080002e0e <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002e0e:	1101                	addi	sp,sp,-32
    80002e10:	ec06                	sd	ra,24(sp)
    80002e12:	e822                	sd	s0,16(sp)
    80002e14:	e426                	sd	s1,8(sp)
    80002e16:	e04a                	sd	s2,0(sp)
    80002e18:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	bac080e7          	jalr	-1108(ra) # 800019c6 <myproc>
    80002e22:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002e24:	05853903          	ld	s2,88(a0)
    80002e28:	0a893783          	ld	a5,168(s2)
    80002e2c:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002e30:	37fd                	addiw	a5,a5,-1
    80002e32:	4759                	li	a4,22
    80002e34:	00f76f63          	bltu	a4,a5,80002e52 <syscall+0x44>
    80002e38:	00369713          	slli	a4,a3,0x3
    80002e3c:	00005797          	auipc	a5,0x5
    80002e40:	61478793          	addi	a5,a5,1556 # 80008450 <syscalls>
    80002e44:	97ba                	add	a5,a5,a4
    80002e46:	639c                	ld	a5,0(a5)
    80002e48:	c789                	beqz	a5,80002e52 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002e4a:	9782                	jalr	a5
    80002e4c:	06a93823          	sd	a0,112(s2)
    80002e50:	a839                	j	80002e6e <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002e52:	15848613          	addi	a2,s1,344
    80002e56:	588c                	lw	a1,48(s1)
    80002e58:	00005517          	auipc	a0,0x5
    80002e5c:	5c050513          	addi	a0,a0,1472 # 80008418 <states.1763+0x150>
    80002e60:	ffffd097          	auipc	ra,0xffffd
    80002e64:	72e080e7          	jalr	1838(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002e68:	6cbc                	ld	a5,88(s1)
    80002e6a:	577d                	li	a4,-1
    80002e6c:	fbb8                	sd	a4,112(a5)
  }
}
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6902                	ld	s2,0(sp)
    80002e76:	6105                	addi	sp,sp,32
    80002e78:	8082                	ret

0000000080002e7a <sys_exit>:
#include "spinlock.h"
#include "proc.h"
// added comment commit check
uint64
sys_exit(void)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002e82:	fec40593          	addi	a1,s0,-20
    80002e86:	4501                	li	a0,0
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	f0e080e7          	jalr	-242(ra) # 80002d96 <argint>
  exit(n);
    80002e90:	fec42503          	lw	a0,-20(s0)
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	30a080e7          	jalr	778(ra) # 8000219e <exit>
  return 0;  // not reached
}
    80002e9c:	4501                	li	a0,0
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret

0000000080002ea6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ea6:	1141                	addi	sp,sp,-16
    80002ea8:	e406                	sd	ra,8(sp)
    80002eaa:	e022                	sd	s0,0(sp)
    80002eac:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	b18080e7          	jalr	-1256(ra) # 800019c6 <myproc>
}
    80002eb6:	5908                	lw	a0,48(a0)
    80002eb8:	60a2                	ld	ra,8(sp)
    80002eba:	6402                	ld	s0,0(sp)
    80002ebc:	0141                	addi	sp,sp,16
    80002ebe:	8082                	ret

0000000080002ec0 <sys_fork>:

uint64
sys_fork(void)
{
    80002ec0:	1141                	addi	sp,sp,-16
    80002ec2:	e406                	sd	ra,8(sp)
    80002ec4:	e022                	sd	s0,0(sp)
    80002ec6:	0800                	addi	s0,sp,16
  return fork();
    80002ec8:	fffff097          	auipc	ra,0xfffff
    80002ecc:	eb4080e7          	jalr	-332(ra) # 80001d7c <fork>
}
    80002ed0:	60a2                	ld	ra,8(sp)
    80002ed2:	6402                	ld	s0,0(sp)
    80002ed4:	0141                	addi	sp,sp,16
    80002ed6:	8082                	ret

0000000080002ed8 <sys_forkn>:

uint64 
sys_forkn(void) 
{
    80002ed8:	1101                	addi	sp,sp,-32
    80002eda:	ec06                	sd	ra,24(sp)
    80002edc:	e822                	sd	s0,16(sp)
    80002ede:	1000                	addi	s0,sp,32
    int n;
    uint64 pids;  // Userspace pointer for child PIDs
    argint(0, &n);
    80002ee0:	fec40593          	addi	a1,s0,-20
    80002ee4:	4501                	li	a0,0
    80002ee6:	00000097          	auipc	ra,0x0
    80002eea:	eb0080e7          	jalr	-336(ra) # 80002d96 <argint>
    argaddr(1, &pids);
    80002eee:	fe040593          	addi	a1,s0,-32
    80002ef2:	4505                	li	a0,1
    80002ef4:	00000097          	auipc	ra,0x0
    80002ef8:	ec2080e7          	jalr	-318(ra) # 80002db6 <argaddr>
   
   return forkn(n, pids);
    80002efc:	fe043583          	ld	a1,-32(s0)
    80002f00:	fec42503          	lw	a0,-20(s0)
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	3e2080e7          	jalr	994(ra) # 800022e6 <forkn>
  }
    80002f0c:	60e2                	ld	ra,24(sp)
    80002f0e:	6442                	ld	s0,16(sp)
    80002f10:	6105                	addi	sp,sp,32
    80002f12:	8082                	ret

0000000080002f14 <sys_wait>:
uint64
sys_wait(void)
{
    80002f14:	1101                	addi	sp,sp,-32
    80002f16:	ec06                	sd	ra,24(sp)
    80002f18:	e822                	sd	s0,16(sp)
    80002f1a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f1c:	fe840593          	addi	a1,s0,-24
    80002f20:	4501                	li	a0,0
    80002f22:	00000097          	auipc	ra,0x0
    80002f26:	e94080e7          	jalr	-364(ra) # 80002db6 <argaddr>
  return wait(p);
    80002f2a:	fe843503          	ld	a0,-24(s0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	4ca080e7          	jalr	1226(ra) # 800023f8 <wait>
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret

0000000080002f3e <sys_waitall>:

uint64
sys_waitall(void) // added
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	1000                	addi	s0,sp,32
  uint64 p; 
  uint64 statuses; 
  
  argaddr(0, &p);
    80002f46:	fe840593          	addi	a1,s0,-24
    80002f4a:	4501                	li	a0,0
    80002f4c:	00000097          	auipc	ra,0x0
    80002f50:	e6a080e7          	jalr	-406(ra) # 80002db6 <argaddr>
  argaddr(1, &statuses);
    80002f54:	fe040593          	addi	a1,s0,-32
    80002f58:	4505                	li	a0,1
    80002f5a:	00000097          	auipc	ra,0x0
    80002f5e:	e5c080e7          	jalr	-420(ra) # 80002db6 <argaddr>
  
  return waitall(p ,statuses);
    80002f62:	fe043583          	ld	a1,-32(s0)
    80002f66:	fe843503          	ld	a0,-24(s0)
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	5bc080e7          	jalr	1468(ra) # 80002526 <waitall>
}
    80002f72:	60e2                	ld	ra,24(sp)
    80002f74:	6442                	ld	s0,16(sp)
    80002f76:	6105                	addi	sp,sp,32
    80002f78:	8082                	ret

0000000080002f7a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f7a:	7179                	addi	sp,sp,-48
    80002f7c:	f406                	sd	ra,40(sp)
    80002f7e:	f022                	sd	s0,32(sp)
    80002f80:	ec26                	sd	s1,24(sp)
    80002f82:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f84:	fdc40593          	addi	a1,s0,-36
    80002f88:	4501                	li	a0,0
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	e0c080e7          	jalr	-500(ra) # 80002d96 <argint>
  addr = myproc()->sz;
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	a34080e7          	jalr	-1484(ra) # 800019c6 <myproc>
    80002f9a:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002f9c:	fdc42503          	lw	a0,-36(s0)
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	d80080e7          	jalr	-640(ra) # 80001d20 <growproc>
    80002fa8:	00054863          	bltz	a0,80002fb8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002fac:	8526                	mv	a0,s1
    80002fae:	70a2                	ld	ra,40(sp)
    80002fb0:	7402                	ld	s0,32(sp)
    80002fb2:	64e2                	ld	s1,24(sp)
    80002fb4:	6145                	addi	sp,sp,48
    80002fb6:	8082                	ret
    return -1;
    80002fb8:	54fd                	li	s1,-1
    80002fba:	bfcd                	j	80002fac <sys_sbrk+0x32>

0000000080002fbc <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fbc:	7139                	addi	sp,sp,-64
    80002fbe:	fc06                	sd	ra,56(sp)
    80002fc0:	f822                	sd	s0,48(sp)
    80002fc2:	f426                	sd	s1,40(sp)
    80002fc4:	f04a                	sd	s2,32(sp)
    80002fc6:	ec4e                	sd	s3,24(sp)
    80002fc8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fca:	fcc40593          	addi	a1,s0,-52
    80002fce:	4501                	li	a0,0
    80002fd0:	00000097          	auipc	ra,0x0
    80002fd4:	dc6080e7          	jalr	-570(ra) # 80002d96 <argint>
  acquire(&tickslock);
    80002fd8:	00014517          	auipc	a0,0x14
    80002fdc:	99850513          	addi	a0,a0,-1640 # 80016970 <tickslock>
    80002fe0:	ffffe097          	auipc	ra,0xffffe
    80002fe4:	c0a080e7          	jalr	-1014(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002fe8:	00006917          	auipc	s2,0x6
    80002fec:	8e892903          	lw	s2,-1816(s2) # 800088d0 <ticks>
  while(ticks - ticks0 < n){
    80002ff0:	fcc42783          	lw	a5,-52(s0)
    80002ff4:	cf9d                	beqz	a5,80003032 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ff6:	00014997          	auipc	s3,0x14
    80002ffa:	97a98993          	addi	s3,s3,-1670 # 80016970 <tickslock>
    80002ffe:	00006497          	auipc	s1,0x6
    80003002:	8d248493          	addi	s1,s1,-1838 # 800088d0 <ticks>
    if(killed(myproc())){
    80003006:	fffff097          	auipc	ra,0xfffff
    8000300a:	9c0080e7          	jalr	-1600(ra) # 800019c6 <myproc>
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	3b8080e7          	jalr	952(ra) # 800023c6 <killed>
    80003016:	ed15                	bnez	a0,80003052 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003018:	85ce                	mv	a1,s3
    8000301a:	8526                	mv	a0,s1
    8000301c:	fffff097          	auipc	ra,0xfffff
    80003020:	04e080e7          	jalr	78(ra) # 8000206a <sleep>
  while(ticks - ticks0 < n){
    80003024:	409c                	lw	a5,0(s1)
    80003026:	412787bb          	subw	a5,a5,s2
    8000302a:	fcc42703          	lw	a4,-52(s0)
    8000302e:	fce7ece3          	bltu	a5,a4,80003006 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	93e50513          	addi	a0,a0,-1730 # 80016970 <tickslock>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c64080e7          	jalr	-924(ra) # 80000c9e <release>
  return 0;
    80003042:	4501                	li	a0,0
}
    80003044:	70e2                	ld	ra,56(sp)
    80003046:	7442                	ld	s0,48(sp)
    80003048:	74a2                	ld	s1,40(sp)
    8000304a:	7902                	ld	s2,32(sp)
    8000304c:	69e2                	ld	s3,24(sp)
    8000304e:	6121                	addi	sp,sp,64
    80003050:	8082                	ret
      release(&tickslock);
    80003052:	00014517          	auipc	a0,0x14
    80003056:	91e50513          	addi	a0,a0,-1762 # 80016970 <tickslock>
    8000305a:	ffffe097          	auipc	ra,0xffffe
    8000305e:	c44080e7          	jalr	-956(ra) # 80000c9e <release>
      return -1;
    80003062:	557d                	li	a0,-1
    80003064:	b7c5                	j	80003044 <sys_sleep+0x88>

0000000080003066 <sys_kill>:

uint64
sys_kill(void)
{
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000306e:	fec40593          	addi	a1,s0,-20
    80003072:	4501                	li	a0,0
    80003074:	00000097          	auipc	ra,0x0
    80003078:	d22080e7          	jalr	-734(ra) # 80002d96 <argint>
  return kill(pid);
    8000307c:	fec42503          	lw	a0,-20(s0)
    80003080:	fffff097          	auipc	ra,0xfffff
    80003084:	1f4080e7          	jalr	500(ra) # 80002274 <kill>
}
    80003088:	60e2                	ld	ra,24(sp)
    8000308a:	6442                	ld	s0,16(sp)
    8000308c:	6105                	addi	sp,sp,32
    8000308e:	8082                	ret

0000000080003090 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003090:	1101                	addi	sp,sp,-32
    80003092:	ec06                	sd	ra,24(sp)
    80003094:	e822                	sd	s0,16(sp)
    80003096:	e426                	sd	s1,8(sp)
    80003098:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000309a:	00014517          	auipc	a0,0x14
    8000309e:	8d650513          	addi	a0,a0,-1834 # 80016970 <tickslock>
    800030a2:	ffffe097          	auipc	ra,0xffffe
    800030a6:	b48080e7          	jalr	-1208(ra) # 80000bea <acquire>
  xticks = ticks;
    800030aa:	00006497          	auipc	s1,0x6
    800030ae:	8264a483          	lw	s1,-2010(s1) # 800088d0 <ticks>
  release(&tickslock);
    800030b2:	00014517          	auipc	a0,0x14
    800030b6:	8be50513          	addi	a0,a0,-1858 # 80016970 <tickslock>
    800030ba:	ffffe097          	auipc	ra,0xffffe
    800030be:	be4080e7          	jalr	-1052(ra) # 80000c9e <release>
  return xticks;
}
    800030c2:	02049513          	slli	a0,s1,0x20
    800030c6:	9101                	srli	a0,a0,0x20
    800030c8:	60e2                	ld	ra,24(sp)
    800030ca:	6442                	ld	s0,16(sp)
    800030cc:	64a2                	ld	s1,8(sp)
    800030ce:	6105                	addi	sp,sp,32
    800030d0:	8082                	ret

00000000800030d2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800030d2:	7179                	addi	sp,sp,-48
    800030d4:	f406                	sd	ra,40(sp)
    800030d6:	f022                	sd	s0,32(sp)
    800030d8:	ec26                	sd	s1,24(sp)
    800030da:	e84a                	sd	s2,16(sp)
    800030dc:	e44e                	sd	s3,8(sp)
    800030de:	e052                	sd	s4,0(sp)
    800030e0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    800030e2:	00005597          	auipc	a1,0x5
    800030e6:	42e58593          	addi	a1,a1,1070 # 80008510 <syscalls+0xc0>
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	89e50513          	addi	a0,a0,-1890 # 80016988 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	a68080e7          	jalr	-1432(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030fa:	0001c797          	auipc	a5,0x1c
    800030fe:	88e78793          	addi	a5,a5,-1906 # 8001e988 <bcache+0x8000>
    80003102:	0001c717          	auipc	a4,0x1c
    80003106:	aee70713          	addi	a4,a4,-1298 # 8001ebf0 <bcache+0x8268>
    8000310a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000310e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003112:	00014497          	auipc	s1,0x14
    80003116:	88e48493          	addi	s1,s1,-1906 # 800169a0 <bcache+0x18>
    b->next = bcache.head.next;
    8000311a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000311c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000311e:	00005a17          	auipc	s4,0x5
    80003122:	3faa0a13          	addi	s4,s4,1018 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003126:	2b893783          	ld	a5,696(s2)
    8000312a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000312c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003130:	85d2                	mv	a1,s4
    80003132:	01048513          	addi	a0,s1,16
    80003136:	00001097          	auipc	ra,0x1
    8000313a:	4c4080e7          	jalr	1220(ra) # 800045fa <initsleeplock>
    bcache.head.next->prev = b;
    8000313e:	2b893783          	ld	a5,696(s2)
    80003142:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003144:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003148:	45848493          	addi	s1,s1,1112
    8000314c:	fd349de3          	bne	s1,s3,80003126 <binit+0x54>
  }
}
    80003150:	70a2                	ld	ra,40(sp)
    80003152:	7402                	ld	s0,32(sp)
    80003154:	64e2                	ld	s1,24(sp)
    80003156:	6942                	ld	s2,16(sp)
    80003158:	69a2                	ld	s3,8(sp)
    8000315a:	6a02                	ld	s4,0(sp)
    8000315c:	6145                	addi	sp,sp,48
    8000315e:	8082                	ret

0000000080003160 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003160:	7179                	addi	sp,sp,-48
    80003162:	f406                	sd	ra,40(sp)
    80003164:	f022                	sd	s0,32(sp)
    80003166:	ec26                	sd	s1,24(sp)
    80003168:	e84a                	sd	s2,16(sp)
    8000316a:	e44e                	sd	s3,8(sp)
    8000316c:	1800                	addi	s0,sp,48
    8000316e:	89aa                	mv	s3,a0
    80003170:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003172:	00014517          	auipc	a0,0x14
    80003176:	81650513          	addi	a0,a0,-2026 # 80016988 <bcache>
    8000317a:	ffffe097          	auipc	ra,0xffffe
    8000317e:	a70080e7          	jalr	-1424(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003182:	0001c497          	auipc	s1,0x1c
    80003186:	abe4b483          	ld	s1,-1346(s1) # 8001ec40 <bcache+0x82b8>
    8000318a:	0001c797          	auipc	a5,0x1c
    8000318e:	a6678793          	addi	a5,a5,-1434 # 8001ebf0 <bcache+0x8268>
    80003192:	02f48f63          	beq	s1,a5,800031d0 <bread+0x70>
    80003196:	873e                	mv	a4,a5
    80003198:	a021                	j	800031a0 <bread+0x40>
    8000319a:	68a4                	ld	s1,80(s1)
    8000319c:	02e48a63          	beq	s1,a4,800031d0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031a0:	449c                	lw	a5,8(s1)
    800031a2:	ff379ce3          	bne	a5,s3,8000319a <bread+0x3a>
    800031a6:	44dc                	lw	a5,12(s1)
    800031a8:	ff2799e3          	bne	a5,s2,8000319a <bread+0x3a>
      b->refcnt++;
    800031ac:	40bc                	lw	a5,64(s1)
    800031ae:	2785                	addiw	a5,a5,1
    800031b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031b2:	00013517          	auipc	a0,0x13
    800031b6:	7d650513          	addi	a0,a0,2006 # 80016988 <bcache>
    800031ba:	ffffe097          	auipc	ra,0xffffe
    800031be:	ae4080e7          	jalr	-1308(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800031c2:	01048513          	addi	a0,s1,16
    800031c6:	00001097          	auipc	ra,0x1
    800031ca:	46e080e7          	jalr	1134(ra) # 80004634 <acquiresleep>
      return b;
    800031ce:	a8b9                	j	8000322c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031d0:	0001c497          	auipc	s1,0x1c
    800031d4:	a684b483          	ld	s1,-1432(s1) # 8001ec38 <bcache+0x82b0>
    800031d8:	0001c797          	auipc	a5,0x1c
    800031dc:	a1878793          	addi	a5,a5,-1512 # 8001ebf0 <bcache+0x8268>
    800031e0:	00f48863          	beq	s1,a5,800031f0 <bread+0x90>
    800031e4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800031e6:	40bc                	lw	a5,64(s1)
    800031e8:	cf81                	beqz	a5,80003200 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800031ea:	64a4                	ld	s1,72(s1)
    800031ec:	fee49de3          	bne	s1,a4,800031e6 <bread+0x86>
  panic("bget: no buffers");
    800031f0:	00005517          	auipc	a0,0x5
    800031f4:	33050513          	addi	a0,a0,816 # 80008520 <syscalls+0xd0>
    800031f8:	ffffd097          	auipc	ra,0xffffd
    800031fc:	34c080e7          	jalr	844(ra) # 80000544 <panic>
      b->dev = dev;
    80003200:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003204:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003208:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000320c:	4785                	li	a5,1
    8000320e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003210:	00013517          	auipc	a0,0x13
    80003214:	77850513          	addi	a0,a0,1912 # 80016988 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	a86080e7          	jalr	-1402(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003220:	01048513          	addi	a0,s1,16
    80003224:	00001097          	auipc	ra,0x1
    80003228:	410080e7          	jalr	1040(ra) # 80004634 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000322c:	409c                	lw	a5,0(s1)
    8000322e:	cb89                	beqz	a5,80003240 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003230:	8526                	mv	a0,s1
    80003232:	70a2                	ld	ra,40(sp)
    80003234:	7402                	ld	s0,32(sp)
    80003236:	64e2                	ld	s1,24(sp)
    80003238:	6942                	ld	s2,16(sp)
    8000323a:	69a2                	ld	s3,8(sp)
    8000323c:	6145                	addi	sp,sp,48
    8000323e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003240:	4581                	li	a1,0
    80003242:	8526                	mv	a0,s1
    80003244:	00003097          	auipc	ra,0x3
    80003248:	fc4080e7          	jalr	-60(ra) # 80006208 <virtio_disk_rw>
    b->valid = 1;
    8000324c:	4785                	li	a5,1
    8000324e:	c09c                	sw	a5,0(s1)
  return b;
    80003250:	b7c5                	j	80003230 <bread+0xd0>

0000000080003252 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003252:	1101                	addi	sp,sp,-32
    80003254:	ec06                	sd	ra,24(sp)
    80003256:	e822                	sd	s0,16(sp)
    80003258:	e426                	sd	s1,8(sp)
    8000325a:	1000                	addi	s0,sp,32
    8000325c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000325e:	0541                	addi	a0,a0,16
    80003260:	00001097          	auipc	ra,0x1
    80003264:	46e080e7          	jalr	1134(ra) # 800046ce <holdingsleep>
    80003268:	cd01                	beqz	a0,80003280 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000326a:	4585                	li	a1,1
    8000326c:	8526                	mv	a0,s1
    8000326e:	00003097          	auipc	ra,0x3
    80003272:	f9a080e7          	jalr	-102(ra) # 80006208 <virtio_disk_rw>
}
    80003276:	60e2                	ld	ra,24(sp)
    80003278:	6442                	ld	s0,16(sp)
    8000327a:	64a2                	ld	s1,8(sp)
    8000327c:	6105                	addi	sp,sp,32
    8000327e:	8082                	ret
    panic("bwrite");
    80003280:	00005517          	auipc	a0,0x5
    80003284:	2b850513          	addi	a0,a0,696 # 80008538 <syscalls+0xe8>
    80003288:	ffffd097          	auipc	ra,0xffffd
    8000328c:	2bc080e7          	jalr	700(ra) # 80000544 <panic>

0000000080003290 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003290:	1101                	addi	sp,sp,-32
    80003292:	ec06                	sd	ra,24(sp)
    80003294:	e822                	sd	s0,16(sp)
    80003296:	e426                	sd	s1,8(sp)
    80003298:	e04a                	sd	s2,0(sp)
    8000329a:	1000                	addi	s0,sp,32
    8000329c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000329e:	01050913          	addi	s2,a0,16
    800032a2:	854a                	mv	a0,s2
    800032a4:	00001097          	auipc	ra,0x1
    800032a8:	42a080e7          	jalr	1066(ra) # 800046ce <holdingsleep>
    800032ac:	c92d                	beqz	a0,8000331e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032ae:	854a                	mv	a0,s2
    800032b0:	00001097          	auipc	ra,0x1
    800032b4:	3da080e7          	jalr	986(ra) # 8000468a <releasesleep>

  acquire(&bcache.lock);
    800032b8:	00013517          	auipc	a0,0x13
    800032bc:	6d050513          	addi	a0,a0,1744 # 80016988 <bcache>
    800032c0:	ffffe097          	auipc	ra,0xffffe
    800032c4:	92a080e7          	jalr	-1750(ra) # 80000bea <acquire>
  b->refcnt--;
    800032c8:	40bc                	lw	a5,64(s1)
    800032ca:	37fd                	addiw	a5,a5,-1
    800032cc:	0007871b          	sext.w	a4,a5
    800032d0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800032d2:	eb05                	bnez	a4,80003302 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800032d4:	68bc                	ld	a5,80(s1)
    800032d6:	64b8                	ld	a4,72(s1)
    800032d8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800032da:	64bc                	ld	a5,72(s1)
    800032dc:	68b8                	ld	a4,80(s1)
    800032de:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800032e0:	0001b797          	auipc	a5,0x1b
    800032e4:	6a878793          	addi	a5,a5,1704 # 8001e988 <bcache+0x8000>
    800032e8:	2b87b703          	ld	a4,696(a5)
    800032ec:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800032ee:	0001c717          	auipc	a4,0x1c
    800032f2:	90270713          	addi	a4,a4,-1790 # 8001ebf0 <bcache+0x8268>
    800032f6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032f8:	2b87b703          	ld	a4,696(a5)
    800032fc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032fe:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003302:	00013517          	auipc	a0,0x13
    80003306:	68650513          	addi	a0,a0,1670 # 80016988 <bcache>
    8000330a:	ffffe097          	auipc	ra,0xffffe
    8000330e:	994080e7          	jalr	-1644(ra) # 80000c9e <release>
}
    80003312:	60e2                	ld	ra,24(sp)
    80003314:	6442                	ld	s0,16(sp)
    80003316:	64a2                	ld	s1,8(sp)
    80003318:	6902                	ld	s2,0(sp)
    8000331a:	6105                	addi	sp,sp,32
    8000331c:	8082                	ret
    panic("brelse");
    8000331e:	00005517          	auipc	a0,0x5
    80003322:	22250513          	addi	a0,a0,546 # 80008540 <syscalls+0xf0>
    80003326:	ffffd097          	auipc	ra,0xffffd
    8000332a:	21e080e7          	jalr	542(ra) # 80000544 <panic>

000000008000332e <bpin>:

void
bpin(struct buf *b) {
    8000332e:	1101                	addi	sp,sp,-32
    80003330:	ec06                	sd	ra,24(sp)
    80003332:	e822                	sd	s0,16(sp)
    80003334:	e426                	sd	s1,8(sp)
    80003336:	1000                	addi	s0,sp,32
    80003338:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000333a:	00013517          	auipc	a0,0x13
    8000333e:	64e50513          	addi	a0,a0,1614 # 80016988 <bcache>
    80003342:	ffffe097          	auipc	ra,0xffffe
    80003346:	8a8080e7          	jalr	-1880(ra) # 80000bea <acquire>
  b->refcnt++;
    8000334a:	40bc                	lw	a5,64(s1)
    8000334c:	2785                	addiw	a5,a5,1
    8000334e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003350:	00013517          	auipc	a0,0x13
    80003354:	63850513          	addi	a0,a0,1592 # 80016988 <bcache>
    80003358:	ffffe097          	auipc	ra,0xffffe
    8000335c:	946080e7          	jalr	-1722(ra) # 80000c9e <release>
}
    80003360:	60e2                	ld	ra,24(sp)
    80003362:	6442                	ld	s0,16(sp)
    80003364:	64a2                	ld	s1,8(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret

000000008000336a <bunpin>:

void
bunpin(struct buf *b) {
    8000336a:	1101                	addi	sp,sp,-32
    8000336c:	ec06                	sd	ra,24(sp)
    8000336e:	e822                	sd	s0,16(sp)
    80003370:	e426                	sd	s1,8(sp)
    80003372:	1000                	addi	s0,sp,32
    80003374:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003376:	00013517          	auipc	a0,0x13
    8000337a:	61250513          	addi	a0,a0,1554 # 80016988 <bcache>
    8000337e:	ffffe097          	auipc	ra,0xffffe
    80003382:	86c080e7          	jalr	-1940(ra) # 80000bea <acquire>
  b->refcnt--;
    80003386:	40bc                	lw	a5,64(s1)
    80003388:	37fd                	addiw	a5,a5,-1
    8000338a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000338c:	00013517          	auipc	a0,0x13
    80003390:	5fc50513          	addi	a0,a0,1532 # 80016988 <bcache>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	90a080e7          	jalr	-1782(ra) # 80000c9e <release>
}
    8000339c:	60e2                	ld	ra,24(sp)
    8000339e:	6442                	ld	s0,16(sp)
    800033a0:	64a2                	ld	s1,8(sp)
    800033a2:	6105                	addi	sp,sp,32
    800033a4:	8082                	ret

00000000800033a6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033a6:	1101                	addi	sp,sp,-32
    800033a8:	ec06                	sd	ra,24(sp)
    800033aa:	e822                	sd	s0,16(sp)
    800033ac:	e426                	sd	s1,8(sp)
    800033ae:	e04a                	sd	s2,0(sp)
    800033b0:	1000                	addi	s0,sp,32
    800033b2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033b4:	00d5d59b          	srliw	a1,a1,0xd
    800033b8:	0001c797          	auipc	a5,0x1c
    800033bc:	cac7a783          	lw	a5,-852(a5) # 8001f064 <sb+0x1c>
    800033c0:	9dbd                	addw	a1,a1,a5
    800033c2:	00000097          	auipc	ra,0x0
    800033c6:	d9e080e7          	jalr	-610(ra) # 80003160 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800033ca:	0074f713          	andi	a4,s1,7
    800033ce:	4785                	li	a5,1
    800033d0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800033d4:	14ce                	slli	s1,s1,0x33
    800033d6:	90d9                	srli	s1,s1,0x36
    800033d8:	00950733          	add	a4,a0,s1
    800033dc:	05874703          	lbu	a4,88(a4)
    800033e0:	00e7f6b3          	and	a3,a5,a4
    800033e4:	c69d                	beqz	a3,80003412 <bfree+0x6c>
    800033e6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800033e8:	94aa                	add	s1,s1,a0
    800033ea:	fff7c793          	not	a5,a5
    800033ee:	8ff9                	and	a5,a5,a4
    800033f0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800033f4:	00001097          	auipc	ra,0x1
    800033f8:	120080e7          	jalr	288(ra) # 80004514 <log_write>
  brelse(bp);
    800033fc:	854a                	mv	a0,s2
    800033fe:	00000097          	auipc	ra,0x0
    80003402:	e92080e7          	jalr	-366(ra) # 80003290 <brelse>
}
    80003406:	60e2                	ld	ra,24(sp)
    80003408:	6442                	ld	s0,16(sp)
    8000340a:	64a2                	ld	s1,8(sp)
    8000340c:	6902                	ld	s2,0(sp)
    8000340e:	6105                	addi	sp,sp,32
    80003410:	8082                	ret
    panic("freeing free block");
    80003412:	00005517          	auipc	a0,0x5
    80003416:	13650513          	addi	a0,a0,310 # 80008548 <syscalls+0xf8>
    8000341a:	ffffd097          	auipc	ra,0xffffd
    8000341e:	12a080e7          	jalr	298(ra) # 80000544 <panic>

0000000080003422 <balloc>:
{
    80003422:	711d                	addi	sp,sp,-96
    80003424:	ec86                	sd	ra,88(sp)
    80003426:	e8a2                	sd	s0,80(sp)
    80003428:	e4a6                	sd	s1,72(sp)
    8000342a:	e0ca                	sd	s2,64(sp)
    8000342c:	fc4e                	sd	s3,56(sp)
    8000342e:	f852                	sd	s4,48(sp)
    80003430:	f456                	sd	s5,40(sp)
    80003432:	f05a                	sd	s6,32(sp)
    80003434:	ec5e                	sd	s7,24(sp)
    80003436:	e862                	sd	s8,16(sp)
    80003438:	e466                	sd	s9,8(sp)
    8000343a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000343c:	0001c797          	auipc	a5,0x1c
    80003440:	c107a783          	lw	a5,-1008(a5) # 8001f04c <sb+0x4>
    80003444:	10078163          	beqz	a5,80003546 <balloc+0x124>
    80003448:	8baa                	mv	s7,a0
    8000344a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000344c:	0001cb17          	auipc	s6,0x1c
    80003450:	bfcb0b13          	addi	s6,s6,-1028 # 8001f048 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003454:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003456:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003458:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000345a:	6c89                	lui	s9,0x2
    8000345c:	a061                	j	800034e4 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000345e:	974a                	add	a4,a4,s2
    80003460:	8fd5                	or	a5,a5,a3
    80003462:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003466:	854a                	mv	a0,s2
    80003468:	00001097          	auipc	ra,0x1
    8000346c:	0ac080e7          	jalr	172(ra) # 80004514 <log_write>
        brelse(bp);
    80003470:	854a                	mv	a0,s2
    80003472:	00000097          	auipc	ra,0x0
    80003476:	e1e080e7          	jalr	-482(ra) # 80003290 <brelse>
  bp = bread(dev, bno);
    8000347a:	85a6                	mv	a1,s1
    8000347c:	855e                	mv	a0,s7
    8000347e:	00000097          	auipc	ra,0x0
    80003482:	ce2080e7          	jalr	-798(ra) # 80003160 <bread>
    80003486:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003488:	40000613          	li	a2,1024
    8000348c:	4581                	li	a1,0
    8000348e:	05850513          	addi	a0,a0,88
    80003492:	ffffe097          	auipc	ra,0xffffe
    80003496:	854080e7          	jalr	-1964(ra) # 80000ce6 <memset>
  log_write(bp);
    8000349a:	854a                	mv	a0,s2
    8000349c:	00001097          	auipc	ra,0x1
    800034a0:	078080e7          	jalr	120(ra) # 80004514 <log_write>
  brelse(bp);
    800034a4:	854a                	mv	a0,s2
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	dea080e7          	jalr	-534(ra) # 80003290 <brelse>
}
    800034ae:	8526                	mv	a0,s1
    800034b0:	60e6                	ld	ra,88(sp)
    800034b2:	6446                	ld	s0,80(sp)
    800034b4:	64a6                	ld	s1,72(sp)
    800034b6:	6906                	ld	s2,64(sp)
    800034b8:	79e2                	ld	s3,56(sp)
    800034ba:	7a42                	ld	s4,48(sp)
    800034bc:	7aa2                	ld	s5,40(sp)
    800034be:	7b02                	ld	s6,32(sp)
    800034c0:	6be2                	ld	s7,24(sp)
    800034c2:	6c42                	ld	s8,16(sp)
    800034c4:	6ca2                	ld	s9,8(sp)
    800034c6:	6125                	addi	sp,sp,96
    800034c8:	8082                	ret
    brelse(bp);
    800034ca:	854a                	mv	a0,s2
    800034cc:	00000097          	auipc	ra,0x0
    800034d0:	dc4080e7          	jalr	-572(ra) # 80003290 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034d4:	015c87bb          	addw	a5,s9,s5
    800034d8:	00078a9b          	sext.w	s5,a5
    800034dc:	004b2703          	lw	a4,4(s6)
    800034e0:	06eaf363          	bgeu	s5,a4,80003546 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800034e4:	41fad79b          	sraiw	a5,s5,0x1f
    800034e8:	0137d79b          	srliw	a5,a5,0x13
    800034ec:	015787bb          	addw	a5,a5,s5
    800034f0:	40d7d79b          	sraiw	a5,a5,0xd
    800034f4:	01cb2583          	lw	a1,28(s6)
    800034f8:	9dbd                	addw	a1,a1,a5
    800034fa:	855e                	mv	a0,s7
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	c64080e7          	jalr	-924(ra) # 80003160 <bread>
    80003504:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003506:	004b2503          	lw	a0,4(s6)
    8000350a:	000a849b          	sext.w	s1,s5
    8000350e:	8662                	mv	a2,s8
    80003510:	faa4fde3          	bgeu	s1,a0,800034ca <balloc+0xa8>
      m = 1 << (bi % 8);
    80003514:	41f6579b          	sraiw	a5,a2,0x1f
    80003518:	01d7d69b          	srliw	a3,a5,0x1d
    8000351c:	00c6873b          	addw	a4,a3,a2
    80003520:	00777793          	andi	a5,a4,7
    80003524:	9f95                	subw	a5,a5,a3
    80003526:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000352a:	4037571b          	sraiw	a4,a4,0x3
    8000352e:	00e906b3          	add	a3,s2,a4
    80003532:	0586c683          	lbu	a3,88(a3)
    80003536:	00d7f5b3          	and	a1,a5,a3
    8000353a:	d195                	beqz	a1,8000345e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000353c:	2605                	addiw	a2,a2,1
    8000353e:	2485                	addiw	s1,s1,1
    80003540:	fd4618e3          	bne	a2,s4,80003510 <balloc+0xee>
    80003544:	b759                	j	800034ca <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003546:	00005517          	auipc	a0,0x5
    8000354a:	01a50513          	addi	a0,a0,26 # 80008560 <syscalls+0x110>
    8000354e:	ffffd097          	auipc	ra,0xffffd
    80003552:	040080e7          	jalr	64(ra) # 8000058e <printf>
  return 0;
    80003556:	4481                	li	s1,0
    80003558:	bf99                	j	800034ae <balloc+0x8c>

000000008000355a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000355a:	7179                	addi	sp,sp,-48
    8000355c:	f406                	sd	ra,40(sp)
    8000355e:	f022                	sd	s0,32(sp)
    80003560:	ec26                	sd	s1,24(sp)
    80003562:	e84a                	sd	s2,16(sp)
    80003564:	e44e                	sd	s3,8(sp)
    80003566:	e052                	sd	s4,0(sp)
    80003568:	1800                	addi	s0,sp,48
    8000356a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000356c:	47ad                	li	a5,11
    8000356e:	02b7e763          	bltu	a5,a1,8000359c <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003572:	02059493          	slli	s1,a1,0x20
    80003576:	9081                	srli	s1,s1,0x20
    80003578:	048a                	slli	s1,s1,0x2
    8000357a:	94aa                	add	s1,s1,a0
    8000357c:	0504a903          	lw	s2,80(s1)
    80003580:	06091e63          	bnez	s2,800035fc <bmap+0xa2>
      addr = balloc(ip->dev);
    80003584:	4108                	lw	a0,0(a0)
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	e9c080e7          	jalr	-356(ra) # 80003422 <balloc>
    8000358e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003592:	06090563          	beqz	s2,800035fc <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003596:	0524a823          	sw	s2,80(s1)
    8000359a:	a08d                	j	800035fc <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000359c:	ff45849b          	addiw	s1,a1,-12
    800035a0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035a4:	0ff00793          	li	a5,255
    800035a8:	08e7e563          	bltu	a5,a4,80003632 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800035ac:	08052903          	lw	s2,128(a0)
    800035b0:	00091d63          	bnez	s2,800035ca <bmap+0x70>
      addr = balloc(ip->dev);
    800035b4:	4108                	lw	a0,0(a0)
    800035b6:	00000097          	auipc	ra,0x0
    800035ba:	e6c080e7          	jalr	-404(ra) # 80003422 <balloc>
    800035be:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800035c2:	02090d63          	beqz	s2,800035fc <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800035c6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800035ca:	85ca                	mv	a1,s2
    800035cc:	0009a503          	lw	a0,0(s3)
    800035d0:	00000097          	auipc	ra,0x0
    800035d4:	b90080e7          	jalr	-1136(ra) # 80003160 <bread>
    800035d8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035da:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035de:	02049593          	slli	a1,s1,0x20
    800035e2:	9181                	srli	a1,a1,0x20
    800035e4:	058a                	slli	a1,a1,0x2
    800035e6:	00b784b3          	add	s1,a5,a1
    800035ea:	0004a903          	lw	s2,0(s1)
    800035ee:	02090063          	beqz	s2,8000360e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800035f2:	8552                	mv	a0,s4
    800035f4:	00000097          	auipc	ra,0x0
    800035f8:	c9c080e7          	jalr	-868(ra) # 80003290 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035fc:	854a                	mv	a0,s2
    800035fe:	70a2                	ld	ra,40(sp)
    80003600:	7402                	ld	s0,32(sp)
    80003602:	64e2                	ld	s1,24(sp)
    80003604:	6942                	ld	s2,16(sp)
    80003606:	69a2                	ld	s3,8(sp)
    80003608:	6a02                	ld	s4,0(sp)
    8000360a:	6145                	addi	sp,sp,48
    8000360c:	8082                	ret
      addr = balloc(ip->dev);
    8000360e:	0009a503          	lw	a0,0(s3)
    80003612:	00000097          	auipc	ra,0x0
    80003616:	e10080e7          	jalr	-496(ra) # 80003422 <balloc>
    8000361a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000361e:	fc090ae3          	beqz	s2,800035f2 <bmap+0x98>
        a[bn] = addr;
    80003622:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003626:	8552                	mv	a0,s4
    80003628:	00001097          	auipc	ra,0x1
    8000362c:	eec080e7          	jalr	-276(ra) # 80004514 <log_write>
    80003630:	b7c9                	j	800035f2 <bmap+0x98>
  panic("bmap: out of range");
    80003632:	00005517          	auipc	a0,0x5
    80003636:	f4650513          	addi	a0,a0,-186 # 80008578 <syscalls+0x128>
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	f0a080e7          	jalr	-246(ra) # 80000544 <panic>

0000000080003642 <iget>:
{
    80003642:	7179                	addi	sp,sp,-48
    80003644:	f406                	sd	ra,40(sp)
    80003646:	f022                	sd	s0,32(sp)
    80003648:	ec26                	sd	s1,24(sp)
    8000364a:	e84a                	sd	s2,16(sp)
    8000364c:	e44e                	sd	s3,8(sp)
    8000364e:	e052                	sd	s4,0(sp)
    80003650:	1800                	addi	s0,sp,48
    80003652:	89aa                	mv	s3,a0
    80003654:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003656:	0001c517          	auipc	a0,0x1c
    8000365a:	a1250513          	addi	a0,a0,-1518 # 8001f068 <itable>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	58c080e7          	jalr	1420(ra) # 80000bea <acquire>
  empty = 0;
    80003666:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003668:	0001c497          	auipc	s1,0x1c
    8000366c:	a1848493          	addi	s1,s1,-1512 # 8001f080 <itable+0x18>
    80003670:	0001d697          	auipc	a3,0x1d
    80003674:	4a068693          	addi	a3,a3,1184 # 80020b10 <log>
    80003678:	a039                	j	80003686 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000367a:	02090b63          	beqz	s2,800036b0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000367e:	08848493          	addi	s1,s1,136
    80003682:	02d48a63          	beq	s1,a3,800036b6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003686:	449c                	lw	a5,8(s1)
    80003688:	fef059e3          	blez	a5,8000367a <iget+0x38>
    8000368c:	4098                	lw	a4,0(s1)
    8000368e:	ff3716e3          	bne	a4,s3,8000367a <iget+0x38>
    80003692:	40d8                	lw	a4,4(s1)
    80003694:	ff4713e3          	bne	a4,s4,8000367a <iget+0x38>
      ip->ref++;
    80003698:	2785                	addiw	a5,a5,1
    8000369a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000369c:	0001c517          	auipc	a0,0x1c
    800036a0:	9cc50513          	addi	a0,a0,-1588 # 8001f068 <itable>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	5fa080e7          	jalr	1530(ra) # 80000c9e <release>
      return ip;
    800036ac:	8926                	mv	s2,s1
    800036ae:	a03d                	j	800036dc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036b0:	f7f9                	bnez	a5,8000367e <iget+0x3c>
    800036b2:	8926                	mv	s2,s1
    800036b4:	b7e9                	j	8000367e <iget+0x3c>
  if(empty == 0)
    800036b6:	02090c63          	beqz	s2,800036ee <iget+0xac>
  ip->dev = dev;
    800036ba:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036be:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036c2:	4785                	li	a5,1
    800036c4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036c8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036cc:	0001c517          	auipc	a0,0x1c
    800036d0:	99c50513          	addi	a0,a0,-1636 # 8001f068 <itable>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	5ca080e7          	jalr	1482(ra) # 80000c9e <release>
}
    800036dc:	854a                	mv	a0,s2
    800036de:	70a2                	ld	ra,40(sp)
    800036e0:	7402                	ld	s0,32(sp)
    800036e2:	64e2                	ld	s1,24(sp)
    800036e4:	6942                	ld	s2,16(sp)
    800036e6:	69a2                	ld	s3,8(sp)
    800036e8:	6a02                	ld	s4,0(sp)
    800036ea:	6145                	addi	sp,sp,48
    800036ec:	8082                	ret
    panic("iget: no inodes");
    800036ee:	00005517          	auipc	a0,0x5
    800036f2:	ea250513          	addi	a0,a0,-350 # 80008590 <syscalls+0x140>
    800036f6:	ffffd097          	auipc	ra,0xffffd
    800036fa:	e4e080e7          	jalr	-434(ra) # 80000544 <panic>

00000000800036fe <fsinit>:
fsinit(int dev) {
    800036fe:	7179                	addi	sp,sp,-48
    80003700:	f406                	sd	ra,40(sp)
    80003702:	f022                	sd	s0,32(sp)
    80003704:	ec26                	sd	s1,24(sp)
    80003706:	e84a                	sd	s2,16(sp)
    80003708:	e44e                	sd	s3,8(sp)
    8000370a:	1800                	addi	s0,sp,48
    8000370c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000370e:	4585                	li	a1,1
    80003710:	00000097          	auipc	ra,0x0
    80003714:	a50080e7          	jalr	-1456(ra) # 80003160 <bread>
    80003718:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000371a:	0001c997          	auipc	s3,0x1c
    8000371e:	92e98993          	addi	s3,s3,-1746 # 8001f048 <sb>
    80003722:	02000613          	li	a2,32
    80003726:	05850593          	addi	a1,a0,88
    8000372a:	854e                	mv	a0,s3
    8000372c:	ffffd097          	auipc	ra,0xffffd
    80003730:	61a080e7          	jalr	1562(ra) # 80000d46 <memmove>
  brelse(bp);
    80003734:	8526                	mv	a0,s1
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	b5a080e7          	jalr	-1190(ra) # 80003290 <brelse>
  if(sb.magic != FSMAGIC)
    8000373e:	0009a703          	lw	a4,0(s3)
    80003742:	102037b7          	lui	a5,0x10203
    80003746:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000374a:	02f71263          	bne	a4,a5,8000376e <fsinit+0x70>
  initlog(dev, &sb);
    8000374e:	0001c597          	auipc	a1,0x1c
    80003752:	8fa58593          	addi	a1,a1,-1798 # 8001f048 <sb>
    80003756:	854a                	mv	a0,s2
    80003758:	00001097          	auipc	ra,0x1
    8000375c:	b40080e7          	jalr	-1216(ra) # 80004298 <initlog>
}
    80003760:	70a2                	ld	ra,40(sp)
    80003762:	7402                	ld	s0,32(sp)
    80003764:	64e2                	ld	s1,24(sp)
    80003766:	6942                	ld	s2,16(sp)
    80003768:	69a2                	ld	s3,8(sp)
    8000376a:	6145                	addi	sp,sp,48
    8000376c:	8082                	ret
    panic("invalid file system");
    8000376e:	00005517          	auipc	a0,0x5
    80003772:	e3250513          	addi	a0,a0,-462 # 800085a0 <syscalls+0x150>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	dce080e7          	jalr	-562(ra) # 80000544 <panic>

000000008000377e <iinit>:
{
    8000377e:	7179                	addi	sp,sp,-48
    80003780:	f406                	sd	ra,40(sp)
    80003782:	f022                	sd	s0,32(sp)
    80003784:	ec26                	sd	s1,24(sp)
    80003786:	e84a                	sd	s2,16(sp)
    80003788:	e44e                	sd	s3,8(sp)
    8000378a:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000378c:	00005597          	auipc	a1,0x5
    80003790:	e2c58593          	addi	a1,a1,-468 # 800085b8 <syscalls+0x168>
    80003794:	0001c517          	auipc	a0,0x1c
    80003798:	8d450513          	addi	a0,a0,-1836 # 8001f068 <itable>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	3be080e7          	jalr	958(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800037a4:	0001c497          	auipc	s1,0x1c
    800037a8:	8ec48493          	addi	s1,s1,-1812 # 8001f090 <itable+0x28>
    800037ac:	0001d997          	auipc	s3,0x1d
    800037b0:	37498993          	addi	s3,s3,884 # 80020b20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037b4:	00005917          	auipc	s2,0x5
    800037b8:	e0c90913          	addi	s2,s2,-500 # 800085c0 <syscalls+0x170>
    800037bc:	85ca                	mv	a1,s2
    800037be:	8526                	mv	a0,s1
    800037c0:	00001097          	auipc	ra,0x1
    800037c4:	e3a080e7          	jalr	-454(ra) # 800045fa <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037c8:	08848493          	addi	s1,s1,136
    800037cc:	ff3498e3          	bne	s1,s3,800037bc <iinit+0x3e>
}
    800037d0:	70a2                	ld	ra,40(sp)
    800037d2:	7402                	ld	s0,32(sp)
    800037d4:	64e2                	ld	s1,24(sp)
    800037d6:	6942                	ld	s2,16(sp)
    800037d8:	69a2                	ld	s3,8(sp)
    800037da:	6145                	addi	sp,sp,48
    800037dc:	8082                	ret

00000000800037de <ialloc>:
{
    800037de:	715d                	addi	sp,sp,-80
    800037e0:	e486                	sd	ra,72(sp)
    800037e2:	e0a2                	sd	s0,64(sp)
    800037e4:	fc26                	sd	s1,56(sp)
    800037e6:	f84a                	sd	s2,48(sp)
    800037e8:	f44e                	sd	s3,40(sp)
    800037ea:	f052                	sd	s4,32(sp)
    800037ec:	ec56                	sd	s5,24(sp)
    800037ee:	e85a                	sd	s6,16(sp)
    800037f0:	e45e                	sd	s7,8(sp)
    800037f2:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800037f4:	0001c717          	auipc	a4,0x1c
    800037f8:	86072703          	lw	a4,-1952(a4) # 8001f054 <sb+0xc>
    800037fc:	4785                	li	a5,1
    800037fe:	04e7fa63          	bgeu	a5,a4,80003852 <ialloc+0x74>
    80003802:	8aaa                	mv	s5,a0
    80003804:	8bae                	mv	s7,a1
    80003806:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003808:	0001ca17          	auipc	s4,0x1c
    8000380c:	840a0a13          	addi	s4,s4,-1984 # 8001f048 <sb>
    80003810:	00048b1b          	sext.w	s6,s1
    80003814:	0044d593          	srli	a1,s1,0x4
    80003818:	018a2783          	lw	a5,24(s4)
    8000381c:	9dbd                	addw	a1,a1,a5
    8000381e:	8556                	mv	a0,s5
    80003820:	00000097          	auipc	ra,0x0
    80003824:	940080e7          	jalr	-1728(ra) # 80003160 <bread>
    80003828:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000382a:	05850993          	addi	s3,a0,88
    8000382e:	00f4f793          	andi	a5,s1,15
    80003832:	079a                	slli	a5,a5,0x6
    80003834:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003836:	00099783          	lh	a5,0(s3)
    8000383a:	c3a1                	beqz	a5,8000387a <ialloc+0x9c>
    brelse(bp);
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	a54080e7          	jalr	-1452(ra) # 80003290 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003844:	0485                	addi	s1,s1,1
    80003846:	00ca2703          	lw	a4,12(s4)
    8000384a:	0004879b          	sext.w	a5,s1
    8000384e:	fce7e1e3          	bltu	a5,a4,80003810 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003852:	00005517          	auipc	a0,0x5
    80003856:	d7650513          	addi	a0,a0,-650 # 800085c8 <syscalls+0x178>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	d34080e7          	jalr	-716(ra) # 8000058e <printf>
  return 0;
    80003862:	4501                	li	a0,0
}
    80003864:	60a6                	ld	ra,72(sp)
    80003866:	6406                	ld	s0,64(sp)
    80003868:	74e2                	ld	s1,56(sp)
    8000386a:	7942                	ld	s2,48(sp)
    8000386c:	79a2                	ld	s3,40(sp)
    8000386e:	7a02                	ld	s4,32(sp)
    80003870:	6ae2                	ld	s5,24(sp)
    80003872:	6b42                	ld	s6,16(sp)
    80003874:	6ba2                	ld	s7,8(sp)
    80003876:	6161                	addi	sp,sp,80
    80003878:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000387a:	04000613          	li	a2,64
    8000387e:	4581                	li	a1,0
    80003880:	854e                	mv	a0,s3
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	464080e7          	jalr	1124(ra) # 80000ce6 <memset>
      dip->type = type;
    8000388a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000388e:	854a                	mv	a0,s2
    80003890:	00001097          	auipc	ra,0x1
    80003894:	c84080e7          	jalr	-892(ra) # 80004514 <log_write>
      brelse(bp);
    80003898:	854a                	mv	a0,s2
    8000389a:	00000097          	auipc	ra,0x0
    8000389e:	9f6080e7          	jalr	-1546(ra) # 80003290 <brelse>
      return iget(dev, inum);
    800038a2:	85da                	mv	a1,s6
    800038a4:	8556                	mv	a0,s5
    800038a6:	00000097          	auipc	ra,0x0
    800038aa:	d9c080e7          	jalr	-612(ra) # 80003642 <iget>
    800038ae:	bf5d                	j	80003864 <ialloc+0x86>

00000000800038b0 <iupdate>:
{
    800038b0:	1101                	addi	sp,sp,-32
    800038b2:	ec06                	sd	ra,24(sp)
    800038b4:	e822                	sd	s0,16(sp)
    800038b6:	e426                	sd	s1,8(sp)
    800038b8:	e04a                	sd	s2,0(sp)
    800038ba:	1000                	addi	s0,sp,32
    800038bc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038be:	415c                	lw	a5,4(a0)
    800038c0:	0047d79b          	srliw	a5,a5,0x4
    800038c4:	0001b597          	auipc	a1,0x1b
    800038c8:	79c5a583          	lw	a1,1948(a1) # 8001f060 <sb+0x18>
    800038cc:	9dbd                	addw	a1,a1,a5
    800038ce:	4108                	lw	a0,0(a0)
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	890080e7          	jalr	-1904(ra) # 80003160 <bread>
    800038d8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038da:	05850793          	addi	a5,a0,88
    800038de:	40c8                	lw	a0,4(s1)
    800038e0:	893d                	andi	a0,a0,15
    800038e2:	051a                	slli	a0,a0,0x6
    800038e4:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800038e6:	04449703          	lh	a4,68(s1)
    800038ea:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800038ee:	04649703          	lh	a4,70(s1)
    800038f2:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038f6:	04849703          	lh	a4,72(s1)
    800038fa:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038fe:	04a49703          	lh	a4,74(s1)
    80003902:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003906:	44f8                	lw	a4,76(s1)
    80003908:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000390a:	03400613          	li	a2,52
    8000390e:	05048593          	addi	a1,s1,80
    80003912:	0531                	addi	a0,a0,12
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	432080e7          	jalr	1074(ra) # 80000d46 <memmove>
  log_write(bp);
    8000391c:	854a                	mv	a0,s2
    8000391e:	00001097          	auipc	ra,0x1
    80003922:	bf6080e7          	jalr	-1034(ra) # 80004514 <log_write>
  brelse(bp);
    80003926:	854a                	mv	a0,s2
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	968080e7          	jalr	-1688(ra) # 80003290 <brelse>
}
    80003930:	60e2                	ld	ra,24(sp)
    80003932:	6442                	ld	s0,16(sp)
    80003934:	64a2                	ld	s1,8(sp)
    80003936:	6902                	ld	s2,0(sp)
    80003938:	6105                	addi	sp,sp,32
    8000393a:	8082                	ret

000000008000393c <idup>:
{
    8000393c:	1101                	addi	sp,sp,-32
    8000393e:	ec06                	sd	ra,24(sp)
    80003940:	e822                	sd	s0,16(sp)
    80003942:	e426                	sd	s1,8(sp)
    80003944:	1000                	addi	s0,sp,32
    80003946:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003948:	0001b517          	auipc	a0,0x1b
    8000394c:	72050513          	addi	a0,a0,1824 # 8001f068 <itable>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	29a080e7          	jalr	666(ra) # 80000bea <acquire>
  ip->ref++;
    80003958:	449c                	lw	a5,8(s1)
    8000395a:	2785                	addiw	a5,a5,1
    8000395c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000395e:	0001b517          	auipc	a0,0x1b
    80003962:	70a50513          	addi	a0,a0,1802 # 8001f068 <itable>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	338080e7          	jalr	824(ra) # 80000c9e <release>
}
    8000396e:	8526                	mv	a0,s1
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6105                	addi	sp,sp,32
    80003978:	8082                	ret

000000008000397a <ilock>:
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	e426                	sd	s1,8(sp)
    80003982:	e04a                	sd	s2,0(sp)
    80003984:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003986:	c115                	beqz	a0,800039aa <ilock+0x30>
    80003988:	84aa                	mv	s1,a0
    8000398a:	451c                	lw	a5,8(a0)
    8000398c:	00f05f63          	blez	a5,800039aa <ilock+0x30>
  acquiresleep(&ip->lock);
    80003990:	0541                	addi	a0,a0,16
    80003992:	00001097          	auipc	ra,0x1
    80003996:	ca2080e7          	jalr	-862(ra) # 80004634 <acquiresleep>
  if(ip->valid == 0){
    8000399a:	40bc                	lw	a5,64(s1)
    8000399c:	cf99                	beqz	a5,800039ba <ilock+0x40>
}
    8000399e:	60e2                	ld	ra,24(sp)
    800039a0:	6442                	ld	s0,16(sp)
    800039a2:	64a2                	ld	s1,8(sp)
    800039a4:	6902                	ld	s2,0(sp)
    800039a6:	6105                	addi	sp,sp,32
    800039a8:	8082                	ret
    panic("ilock");
    800039aa:	00005517          	auipc	a0,0x5
    800039ae:	c3650513          	addi	a0,a0,-970 # 800085e0 <syscalls+0x190>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	b92080e7          	jalr	-1134(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039ba:	40dc                	lw	a5,4(s1)
    800039bc:	0047d79b          	srliw	a5,a5,0x4
    800039c0:	0001b597          	auipc	a1,0x1b
    800039c4:	6a05a583          	lw	a1,1696(a1) # 8001f060 <sb+0x18>
    800039c8:	9dbd                	addw	a1,a1,a5
    800039ca:	4088                	lw	a0,0(s1)
    800039cc:	fffff097          	auipc	ra,0xfffff
    800039d0:	794080e7          	jalr	1940(ra) # 80003160 <bread>
    800039d4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800039d6:	05850593          	addi	a1,a0,88
    800039da:	40dc                	lw	a5,4(s1)
    800039dc:	8bbd                	andi	a5,a5,15
    800039de:	079a                	slli	a5,a5,0x6
    800039e0:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800039e2:	00059783          	lh	a5,0(a1)
    800039e6:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800039ea:	00259783          	lh	a5,2(a1)
    800039ee:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800039f2:	00459783          	lh	a5,4(a1)
    800039f6:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039fa:	00659783          	lh	a5,6(a1)
    800039fe:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a02:	459c                	lw	a5,8(a1)
    80003a04:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a06:	03400613          	li	a2,52
    80003a0a:	05b1                	addi	a1,a1,12
    80003a0c:	05048513          	addi	a0,s1,80
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	336080e7          	jalr	822(ra) # 80000d46 <memmove>
    brelse(bp);
    80003a18:	854a                	mv	a0,s2
    80003a1a:	00000097          	auipc	ra,0x0
    80003a1e:	876080e7          	jalr	-1930(ra) # 80003290 <brelse>
    ip->valid = 1;
    80003a22:	4785                	li	a5,1
    80003a24:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a26:	04449783          	lh	a5,68(s1)
    80003a2a:	fbb5                	bnez	a5,8000399e <ilock+0x24>
      panic("ilock: no type");
    80003a2c:	00005517          	auipc	a0,0x5
    80003a30:	bbc50513          	addi	a0,a0,-1092 # 800085e8 <syscalls+0x198>
    80003a34:	ffffd097          	auipc	ra,0xffffd
    80003a38:	b10080e7          	jalr	-1264(ra) # 80000544 <panic>

0000000080003a3c <iunlock>:
{
    80003a3c:	1101                	addi	sp,sp,-32
    80003a3e:	ec06                	sd	ra,24(sp)
    80003a40:	e822                	sd	s0,16(sp)
    80003a42:	e426                	sd	s1,8(sp)
    80003a44:	e04a                	sd	s2,0(sp)
    80003a46:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a48:	c905                	beqz	a0,80003a78 <iunlock+0x3c>
    80003a4a:	84aa                	mv	s1,a0
    80003a4c:	01050913          	addi	s2,a0,16
    80003a50:	854a                	mv	a0,s2
    80003a52:	00001097          	auipc	ra,0x1
    80003a56:	c7c080e7          	jalr	-900(ra) # 800046ce <holdingsleep>
    80003a5a:	cd19                	beqz	a0,80003a78 <iunlock+0x3c>
    80003a5c:	449c                	lw	a5,8(s1)
    80003a5e:	00f05d63          	blez	a5,80003a78 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a62:	854a                	mv	a0,s2
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	c26080e7          	jalr	-986(ra) # 8000468a <releasesleep>
}
    80003a6c:	60e2                	ld	ra,24(sp)
    80003a6e:	6442                	ld	s0,16(sp)
    80003a70:	64a2                	ld	s1,8(sp)
    80003a72:	6902                	ld	s2,0(sp)
    80003a74:	6105                	addi	sp,sp,32
    80003a76:	8082                	ret
    panic("iunlock");
    80003a78:	00005517          	auipc	a0,0x5
    80003a7c:	b8050513          	addi	a0,a0,-1152 # 800085f8 <syscalls+0x1a8>
    80003a80:	ffffd097          	auipc	ra,0xffffd
    80003a84:	ac4080e7          	jalr	-1340(ra) # 80000544 <panic>

0000000080003a88 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a88:	7179                	addi	sp,sp,-48
    80003a8a:	f406                	sd	ra,40(sp)
    80003a8c:	f022                	sd	s0,32(sp)
    80003a8e:	ec26                	sd	s1,24(sp)
    80003a90:	e84a                	sd	s2,16(sp)
    80003a92:	e44e                	sd	s3,8(sp)
    80003a94:	e052                	sd	s4,0(sp)
    80003a96:	1800                	addi	s0,sp,48
    80003a98:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a9a:	05050493          	addi	s1,a0,80
    80003a9e:	08050913          	addi	s2,a0,128
    80003aa2:	a021                	j	80003aaa <itrunc+0x22>
    80003aa4:	0491                	addi	s1,s1,4
    80003aa6:	01248d63          	beq	s1,s2,80003ac0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003aaa:	408c                	lw	a1,0(s1)
    80003aac:	dde5                	beqz	a1,80003aa4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aae:	0009a503          	lw	a0,0(s3)
    80003ab2:	00000097          	auipc	ra,0x0
    80003ab6:	8f4080e7          	jalr	-1804(ra) # 800033a6 <bfree>
      ip->addrs[i] = 0;
    80003aba:	0004a023          	sw	zero,0(s1)
    80003abe:	b7dd                	j	80003aa4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ac0:	0809a583          	lw	a1,128(s3)
    80003ac4:	e185                	bnez	a1,80003ae4 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003ac6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003aca:	854e                	mv	a0,s3
    80003acc:	00000097          	auipc	ra,0x0
    80003ad0:	de4080e7          	jalr	-540(ra) # 800038b0 <iupdate>
}
    80003ad4:	70a2                	ld	ra,40(sp)
    80003ad6:	7402                	ld	s0,32(sp)
    80003ad8:	64e2                	ld	s1,24(sp)
    80003ada:	6942                	ld	s2,16(sp)
    80003adc:	69a2                	ld	s3,8(sp)
    80003ade:	6a02                	ld	s4,0(sp)
    80003ae0:	6145                	addi	sp,sp,48
    80003ae2:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003ae4:	0009a503          	lw	a0,0(s3)
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	678080e7          	jalr	1656(ra) # 80003160 <bread>
    80003af0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003af2:	05850493          	addi	s1,a0,88
    80003af6:	45850913          	addi	s2,a0,1112
    80003afa:	a811                	j	80003b0e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003afc:	0009a503          	lw	a0,0(s3)
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	8a6080e7          	jalr	-1882(ra) # 800033a6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b08:	0491                	addi	s1,s1,4
    80003b0a:	01248563          	beq	s1,s2,80003b14 <itrunc+0x8c>
      if(a[j])
    80003b0e:	408c                	lw	a1,0(s1)
    80003b10:	dde5                	beqz	a1,80003b08 <itrunc+0x80>
    80003b12:	b7ed                	j	80003afc <itrunc+0x74>
    brelse(bp);
    80003b14:	8552                	mv	a0,s4
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	77a080e7          	jalr	1914(ra) # 80003290 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b1e:	0809a583          	lw	a1,128(s3)
    80003b22:	0009a503          	lw	a0,0(s3)
    80003b26:	00000097          	auipc	ra,0x0
    80003b2a:	880080e7          	jalr	-1920(ra) # 800033a6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b2e:	0809a023          	sw	zero,128(s3)
    80003b32:	bf51                	j	80003ac6 <itrunc+0x3e>

0000000080003b34 <iput>:
{
    80003b34:	1101                	addi	sp,sp,-32
    80003b36:	ec06                	sd	ra,24(sp)
    80003b38:	e822                	sd	s0,16(sp)
    80003b3a:	e426                	sd	s1,8(sp)
    80003b3c:	e04a                	sd	s2,0(sp)
    80003b3e:	1000                	addi	s0,sp,32
    80003b40:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b42:	0001b517          	auipc	a0,0x1b
    80003b46:	52650513          	addi	a0,a0,1318 # 8001f068 <itable>
    80003b4a:	ffffd097          	auipc	ra,0xffffd
    80003b4e:	0a0080e7          	jalr	160(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b52:	4498                	lw	a4,8(s1)
    80003b54:	4785                	li	a5,1
    80003b56:	02f70363          	beq	a4,a5,80003b7c <iput+0x48>
  ip->ref--;
    80003b5a:	449c                	lw	a5,8(s1)
    80003b5c:	37fd                	addiw	a5,a5,-1
    80003b5e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b60:	0001b517          	auipc	a0,0x1b
    80003b64:	50850513          	addi	a0,a0,1288 # 8001f068 <itable>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	136080e7          	jalr	310(ra) # 80000c9e <release>
}
    80003b70:	60e2                	ld	ra,24(sp)
    80003b72:	6442                	ld	s0,16(sp)
    80003b74:	64a2                	ld	s1,8(sp)
    80003b76:	6902                	ld	s2,0(sp)
    80003b78:	6105                	addi	sp,sp,32
    80003b7a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b7c:	40bc                	lw	a5,64(s1)
    80003b7e:	dff1                	beqz	a5,80003b5a <iput+0x26>
    80003b80:	04a49783          	lh	a5,74(s1)
    80003b84:	fbf9                	bnez	a5,80003b5a <iput+0x26>
    acquiresleep(&ip->lock);
    80003b86:	01048913          	addi	s2,s1,16
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00001097          	auipc	ra,0x1
    80003b90:	aa8080e7          	jalr	-1368(ra) # 80004634 <acquiresleep>
    release(&itable.lock);
    80003b94:	0001b517          	auipc	a0,0x1b
    80003b98:	4d450513          	addi	a0,a0,1236 # 8001f068 <itable>
    80003b9c:	ffffd097          	auipc	ra,0xffffd
    80003ba0:	102080e7          	jalr	258(ra) # 80000c9e <release>
    itrunc(ip);
    80003ba4:	8526                	mv	a0,s1
    80003ba6:	00000097          	auipc	ra,0x0
    80003baa:	ee2080e7          	jalr	-286(ra) # 80003a88 <itrunc>
    ip->type = 0;
    80003bae:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	cfc080e7          	jalr	-772(ra) # 800038b0 <iupdate>
    ip->valid = 0;
    80003bbc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bc0:	854a                	mv	a0,s2
    80003bc2:	00001097          	auipc	ra,0x1
    80003bc6:	ac8080e7          	jalr	-1336(ra) # 8000468a <releasesleep>
    acquire(&itable.lock);
    80003bca:	0001b517          	auipc	a0,0x1b
    80003bce:	49e50513          	addi	a0,a0,1182 # 8001f068 <itable>
    80003bd2:	ffffd097          	auipc	ra,0xffffd
    80003bd6:	018080e7          	jalr	24(ra) # 80000bea <acquire>
    80003bda:	b741                	j	80003b5a <iput+0x26>

0000000080003bdc <iunlockput>:
{
    80003bdc:	1101                	addi	sp,sp,-32
    80003bde:	ec06                	sd	ra,24(sp)
    80003be0:	e822                	sd	s0,16(sp)
    80003be2:	e426                	sd	s1,8(sp)
    80003be4:	1000                	addi	s0,sp,32
    80003be6:	84aa                	mv	s1,a0
  iunlock(ip);
    80003be8:	00000097          	auipc	ra,0x0
    80003bec:	e54080e7          	jalr	-428(ra) # 80003a3c <iunlock>
  iput(ip);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	f42080e7          	jalr	-190(ra) # 80003b34 <iput>
}
    80003bfa:	60e2                	ld	ra,24(sp)
    80003bfc:	6442                	ld	s0,16(sp)
    80003bfe:	64a2                	ld	s1,8(sp)
    80003c00:	6105                	addi	sp,sp,32
    80003c02:	8082                	ret

0000000080003c04 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c04:	1141                	addi	sp,sp,-16
    80003c06:	e422                	sd	s0,8(sp)
    80003c08:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c0a:	411c                	lw	a5,0(a0)
    80003c0c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c0e:	415c                	lw	a5,4(a0)
    80003c10:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c12:	04451783          	lh	a5,68(a0)
    80003c16:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c1a:	04a51783          	lh	a5,74(a0)
    80003c1e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c22:	04c56783          	lwu	a5,76(a0)
    80003c26:	e99c                	sd	a5,16(a1)
}
    80003c28:	6422                	ld	s0,8(sp)
    80003c2a:	0141                	addi	sp,sp,16
    80003c2c:	8082                	ret

0000000080003c2e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c2e:	457c                	lw	a5,76(a0)
    80003c30:	0ed7e963          	bltu	a5,a3,80003d22 <readi+0xf4>
{
    80003c34:	7159                	addi	sp,sp,-112
    80003c36:	f486                	sd	ra,104(sp)
    80003c38:	f0a2                	sd	s0,96(sp)
    80003c3a:	eca6                	sd	s1,88(sp)
    80003c3c:	e8ca                	sd	s2,80(sp)
    80003c3e:	e4ce                	sd	s3,72(sp)
    80003c40:	e0d2                	sd	s4,64(sp)
    80003c42:	fc56                	sd	s5,56(sp)
    80003c44:	f85a                	sd	s6,48(sp)
    80003c46:	f45e                	sd	s7,40(sp)
    80003c48:	f062                	sd	s8,32(sp)
    80003c4a:	ec66                	sd	s9,24(sp)
    80003c4c:	e86a                	sd	s10,16(sp)
    80003c4e:	e46e                	sd	s11,8(sp)
    80003c50:	1880                	addi	s0,sp,112
    80003c52:	8b2a                	mv	s6,a0
    80003c54:	8bae                	mv	s7,a1
    80003c56:	8a32                	mv	s4,a2
    80003c58:	84b6                	mv	s1,a3
    80003c5a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c5c:	9f35                	addw	a4,a4,a3
    return 0;
    80003c5e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c60:	0ad76063          	bltu	a4,a3,80003d00 <readi+0xd2>
  if(off + n > ip->size)
    80003c64:	00e7f463          	bgeu	a5,a4,80003c6c <readi+0x3e>
    n = ip->size - off;
    80003c68:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c6c:	0a0a8963          	beqz	s5,80003d1e <readi+0xf0>
    80003c70:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c72:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c76:	5c7d                	li	s8,-1
    80003c78:	a82d                	j	80003cb2 <readi+0x84>
    80003c7a:	020d1d93          	slli	s11,s10,0x20
    80003c7e:	020ddd93          	srli	s11,s11,0x20
    80003c82:	05890613          	addi	a2,s2,88
    80003c86:	86ee                	mv	a3,s11
    80003c88:	963a                	add	a2,a2,a4
    80003c8a:	85d2                	mv	a1,s4
    80003c8c:	855e                	mv	a0,s7
    80003c8e:	fffff097          	auipc	ra,0xfffff
    80003c92:	aa4080e7          	jalr	-1372(ra) # 80002732 <either_copyout>
    80003c96:	05850d63          	beq	a0,s8,80003cf0 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	5f4080e7          	jalr	1524(ra) # 80003290 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ca4:	013d09bb          	addw	s3,s10,s3
    80003ca8:	009d04bb          	addw	s1,s10,s1
    80003cac:	9a6e                	add	s4,s4,s11
    80003cae:	0559f763          	bgeu	s3,s5,80003cfc <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003cb2:	00a4d59b          	srliw	a1,s1,0xa
    80003cb6:	855a                	mv	a0,s6
    80003cb8:	00000097          	auipc	ra,0x0
    80003cbc:	8a2080e7          	jalr	-1886(ra) # 8000355a <bmap>
    80003cc0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cc4:	cd85                	beqz	a1,80003cfc <readi+0xce>
    bp = bread(ip->dev, addr);
    80003cc6:	000b2503          	lw	a0,0(s6)
    80003cca:	fffff097          	auipc	ra,0xfffff
    80003cce:	496080e7          	jalr	1174(ra) # 80003160 <bread>
    80003cd2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd4:	3ff4f713          	andi	a4,s1,1023
    80003cd8:	40ec87bb          	subw	a5,s9,a4
    80003cdc:	413a86bb          	subw	a3,s5,s3
    80003ce0:	8d3e                	mv	s10,a5
    80003ce2:	2781                	sext.w	a5,a5
    80003ce4:	0006861b          	sext.w	a2,a3
    80003ce8:	f8f679e3          	bgeu	a2,a5,80003c7a <readi+0x4c>
    80003cec:	8d36                	mv	s10,a3
    80003cee:	b771                	j	80003c7a <readi+0x4c>
      brelse(bp);
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	59e080e7          	jalr	1438(ra) # 80003290 <brelse>
      tot = -1;
    80003cfa:	59fd                	li	s3,-1
  }
  return tot;
    80003cfc:	0009851b          	sext.w	a0,s3
}
    80003d00:	70a6                	ld	ra,104(sp)
    80003d02:	7406                	ld	s0,96(sp)
    80003d04:	64e6                	ld	s1,88(sp)
    80003d06:	6946                	ld	s2,80(sp)
    80003d08:	69a6                	ld	s3,72(sp)
    80003d0a:	6a06                	ld	s4,64(sp)
    80003d0c:	7ae2                	ld	s5,56(sp)
    80003d0e:	7b42                	ld	s6,48(sp)
    80003d10:	7ba2                	ld	s7,40(sp)
    80003d12:	7c02                	ld	s8,32(sp)
    80003d14:	6ce2                	ld	s9,24(sp)
    80003d16:	6d42                	ld	s10,16(sp)
    80003d18:	6da2                	ld	s11,8(sp)
    80003d1a:	6165                	addi	sp,sp,112
    80003d1c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d1e:	89d6                	mv	s3,s5
    80003d20:	bff1                	j	80003cfc <readi+0xce>
    return 0;
    80003d22:	4501                	li	a0,0
}
    80003d24:	8082                	ret

0000000080003d26 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d26:	457c                	lw	a5,76(a0)
    80003d28:	10d7e863          	bltu	a5,a3,80003e38 <writei+0x112>
{
    80003d2c:	7159                	addi	sp,sp,-112
    80003d2e:	f486                	sd	ra,104(sp)
    80003d30:	f0a2                	sd	s0,96(sp)
    80003d32:	eca6                	sd	s1,88(sp)
    80003d34:	e8ca                	sd	s2,80(sp)
    80003d36:	e4ce                	sd	s3,72(sp)
    80003d38:	e0d2                	sd	s4,64(sp)
    80003d3a:	fc56                	sd	s5,56(sp)
    80003d3c:	f85a                	sd	s6,48(sp)
    80003d3e:	f45e                	sd	s7,40(sp)
    80003d40:	f062                	sd	s8,32(sp)
    80003d42:	ec66                	sd	s9,24(sp)
    80003d44:	e86a                	sd	s10,16(sp)
    80003d46:	e46e                	sd	s11,8(sp)
    80003d48:	1880                	addi	s0,sp,112
    80003d4a:	8aaa                	mv	s5,a0
    80003d4c:	8bae                	mv	s7,a1
    80003d4e:	8a32                	mv	s4,a2
    80003d50:	8936                	mv	s2,a3
    80003d52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d54:	00e687bb          	addw	a5,a3,a4
    80003d58:	0ed7e263          	bltu	a5,a3,80003e3c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d5c:	00043737          	lui	a4,0x43
    80003d60:	0ef76063          	bltu	a4,a5,80003e40 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d64:	0c0b0863          	beqz	s6,80003e34 <writei+0x10e>
    80003d68:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d6a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d6e:	5c7d                	li	s8,-1
    80003d70:	a091                	j	80003db4 <writei+0x8e>
    80003d72:	020d1d93          	slli	s11,s10,0x20
    80003d76:	020ddd93          	srli	s11,s11,0x20
    80003d7a:	05848513          	addi	a0,s1,88
    80003d7e:	86ee                	mv	a3,s11
    80003d80:	8652                	mv	a2,s4
    80003d82:	85de                	mv	a1,s7
    80003d84:	953a                	add	a0,a0,a4
    80003d86:	fffff097          	auipc	ra,0xfffff
    80003d8a:	a02080e7          	jalr	-1534(ra) # 80002788 <either_copyin>
    80003d8e:	07850263          	beq	a0,s8,80003df2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d92:	8526                	mv	a0,s1
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	780080e7          	jalr	1920(ra) # 80004514 <log_write>
    brelse(bp);
    80003d9c:	8526                	mv	a0,s1
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	4f2080e7          	jalr	1266(ra) # 80003290 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da6:	013d09bb          	addw	s3,s10,s3
    80003daa:	012d093b          	addw	s2,s10,s2
    80003dae:	9a6e                	add	s4,s4,s11
    80003db0:	0569f663          	bgeu	s3,s6,80003dfc <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003db4:	00a9559b          	srliw	a1,s2,0xa
    80003db8:	8556                	mv	a0,s5
    80003dba:	fffff097          	auipc	ra,0xfffff
    80003dbe:	7a0080e7          	jalr	1952(ra) # 8000355a <bmap>
    80003dc2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003dc6:	c99d                	beqz	a1,80003dfc <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003dc8:	000aa503          	lw	a0,0(s5)
    80003dcc:	fffff097          	auipc	ra,0xfffff
    80003dd0:	394080e7          	jalr	916(ra) # 80003160 <bread>
    80003dd4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dd6:	3ff97713          	andi	a4,s2,1023
    80003dda:	40ec87bb          	subw	a5,s9,a4
    80003dde:	413b06bb          	subw	a3,s6,s3
    80003de2:	8d3e                	mv	s10,a5
    80003de4:	2781                	sext.w	a5,a5
    80003de6:	0006861b          	sext.w	a2,a3
    80003dea:	f8f674e3          	bgeu	a2,a5,80003d72 <writei+0x4c>
    80003dee:	8d36                	mv	s10,a3
    80003df0:	b749                	j	80003d72 <writei+0x4c>
      brelse(bp);
    80003df2:	8526                	mv	a0,s1
    80003df4:	fffff097          	auipc	ra,0xfffff
    80003df8:	49c080e7          	jalr	1180(ra) # 80003290 <brelse>
  }

  if(off > ip->size)
    80003dfc:	04caa783          	lw	a5,76(s5)
    80003e00:	0127f463          	bgeu	a5,s2,80003e08 <writei+0xe2>
    ip->size = off;
    80003e04:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e08:	8556                	mv	a0,s5
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	aa6080e7          	jalr	-1370(ra) # 800038b0 <iupdate>

  return tot;
    80003e12:	0009851b          	sext.w	a0,s3
}
    80003e16:	70a6                	ld	ra,104(sp)
    80003e18:	7406                	ld	s0,96(sp)
    80003e1a:	64e6                	ld	s1,88(sp)
    80003e1c:	6946                	ld	s2,80(sp)
    80003e1e:	69a6                	ld	s3,72(sp)
    80003e20:	6a06                	ld	s4,64(sp)
    80003e22:	7ae2                	ld	s5,56(sp)
    80003e24:	7b42                	ld	s6,48(sp)
    80003e26:	7ba2                	ld	s7,40(sp)
    80003e28:	7c02                	ld	s8,32(sp)
    80003e2a:	6ce2                	ld	s9,24(sp)
    80003e2c:	6d42                	ld	s10,16(sp)
    80003e2e:	6da2                	ld	s11,8(sp)
    80003e30:	6165                	addi	sp,sp,112
    80003e32:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e34:	89da                	mv	s3,s6
    80003e36:	bfc9                	j	80003e08 <writei+0xe2>
    return -1;
    80003e38:	557d                	li	a0,-1
}
    80003e3a:	8082                	ret
    return -1;
    80003e3c:	557d                	li	a0,-1
    80003e3e:	bfe1                	j	80003e16 <writei+0xf0>
    return -1;
    80003e40:	557d                	li	a0,-1
    80003e42:	bfd1                	j	80003e16 <writei+0xf0>

0000000080003e44 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e44:	1141                	addi	sp,sp,-16
    80003e46:	e406                	sd	ra,8(sp)
    80003e48:	e022                	sd	s0,0(sp)
    80003e4a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e4c:	4639                	li	a2,14
    80003e4e:	ffffd097          	auipc	ra,0xffffd
    80003e52:	f70080e7          	jalr	-144(ra) # 80000dbe <strncmp>
}
    80003e56:	60a2                	ld	ra,8(sp)
    80003e58:	6402                	ld	s0,0(sp)
    80003e5a:	0141                	addi	sp,sp,16
    80003e5c:	8082                	ret

0000000080003e5e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e5e:	7139                	addi	sp,sp,-64
    80003e60:	fc06                	sd	ra,56(sp)
    80003e62:	f822                	sd	s0,48(sp)
    80003e64:	f426                	sd	s1,40(sp)
    80003e66:	f04a                	sd	s2,32(sp)
    80003e68:	ec4e                	sd	s3,24(sp)
    80003e6a:	e852                	sd	s4,16(sp)
    80003e6c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e6e:	04451703          	lh	a4,68(a0)
    80003e72:	4785                	li	a5,1
    80003e74:	00f71a63          	bne	a4,a5,80003e88 <dirlookup+0x2a>
    80003e78:	892a                	mv	s2,a0
    80003e7a:	89ae                	mv	s3,a1
    80003e7c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e7e:	457c                	lw	a5,76(a0)
    80003e80:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e82:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e84:	e79d                	bnez	a5,80003eb2 <dirlookup+0x54>
    80003e86:	a8a5                	j	80003efe <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e88:	00004517          	auipc	a0,0x4
    80003e8c:	77850513          	addi	a0,a0,1912 # 80008600 <syscalls+0x1b0>
    80003e90:	ffffc097          	auipc	ra,0xffffc
    80003e94:	6b4080e7          	jalr	1716(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003e98:	00004517          	auipc	a0,0x4
    80003e9c:	78050513          	addi	a0,a0,1920 # 80008618 <syscalls+0x1c8>
    80003ea0:	ffffc097          	auipc	ra,0xffffc
    80003ea4:	6a4080e7          	jalr	1700(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ea8:	24c1                	addiw	s1,s1,16
    80003eaa:	04c92783          	lw	a5,76(s2)
    80003eae:	04f4f763          	bgeu	s1,a5,80003efc <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb2:	4741                	li	a4,16
    80003eb4:	86a6                	mv	a3,s1
    80003eb6:	fc040613          	addi	a2,s0,-64
    80003eba:	4581                	li	a1,0
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	d70080e7          	jalr	-656(ra) # 80003c2e <readi>
    80003ec6:	47c1                	li	a5,16
    80003ec8:	fcf518e3          	bne	a0,a5,80003e98 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ecc:	fc045783          	lhu	a5,-64(s0)
    80003ed0:	dfe1                	beqz	a5,80003ea8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003ed2:	fc240593          	addi	a1,s0,-62
    80003ed6:	854e                	mv	a0,s3
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	f6c080e7          	jalr	-148(ra) # 80003e44 <namecmp>
    80003ee0:	f561                	bnez	a0,80003ea8 <dirlookup+0x4a>
      if(poff)
    80003ee2:	000a0463          	beqz	s4,80003eea <dirlookup+0x8c>
        *poff = off;
    80003ee6:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003eea:	fc045583          	lhu	a1,-64(s0)
    80003eee:	00092503          	lw	a0,0(s2)
    80003ef2:	fffff097          	auipc	ra,0xfffff
    80003ef6:	750080e7          	jalr	1872(ra) # 80003642 <iget>
    80003efa:	a011                	j	80003efe <dirlookup+0xa0>
  return 0;
    80003efc:	4501                	li	a0,0
}
    80003efe:	70e2                	ld	ra,56(sp)
    80003f00:	7442                	ld	s0,48(sp)
    80003f02:	74a2                	ld	s1,40(sp)
    80003f04:	7902                	ld	s2,32(sp)
    80003f06:	69e2                	ld	s3,24(sp)
    80003f08:	6a42                	ld	s4,16(sp)
    80003f0a:	6121                	addi	sp,sp,64
    80003f0c:	8082                	ret

0000000080003f0e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f0e:	711d                	addi	sp,sp,-96
    80003f10:	ec86                	sd	ra,88(sp)
    80003f12:	e8a2                	sd	s0,80(sp)
    80003f14:	e4a6                	sd	s1,72(sp)
    80003f16:	e0ca                	sd	s2,64(sp)
    80003f18:	fc4e                	sd	s3,56(sp)
    80003f1a:	f852                	sd	s4,48(sp)
    80003f1c:	f456                	sd	s5,40(sp)
    80003f1e:	f05a                	sd	s6,32(sp)
    80003f20:	ec5e                	sd	s7,24(sp)
    80003f22:	e862                	sd	s8,16(sp)
    80003f24:	e466                	sd	s9,8(sp)
    80003f26:	1080                	addi	s0,sp,96
    80003f28:	84aa                	mv	s1,a0
    80003f2a:	8b2e                	mv	s6,a1
    80003f2c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f2e:	00054703          	lbu	a4,0(a0)
    80003f32:	02f00793          	li	a5,47
    80003f36:	02f70363          	beq	a4,a5,80003f5c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f3a:	ffffe097          	auipc	ra,0xffffe
    80003f3e:	a8c080e7          	jalr	-1396(ra) # 800019c6 <myproc>
    80003f42:	15053503          	ld	a0,336(a0)
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	9f6080e7          	jalr	-1546(ra) # 8000393c <idup>
    80003f4e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f50:	02f00913          	li	s2,47
  len = path - s;
    80003f54:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f56:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f58:	4c05                	li	s8,1
    80003f5a:	a865                	j	80004012 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f5c:	4585                	li	a1,1
    80003f5e:	4505                	li	a0,1
    80003f60:	fffff097          	auipc	ra,0xfffff
    80003f64:	6e2080e7          	jalr	1762(ra) # 80003642 <iget>
    80003f68:	89aa                	mv	s3,a0
    80003f6a:	b7dd                	j	80003f50 <namex+0x42>
      iunlockput(ip);
    80003f6c:	854e                	mv	a0,s3
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	c6e080e7          	jalr	-914(ra) # 80003bdc <iunlockput>
      return 0;
    80003f76:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f78:	854e                	mv	a0,s3
    80003f7a:	60e6                	ld	ra,88(sp)
    80003f7c:	6446                	ld	s0,80(sp)
    80003f7e:	64a6                	ld	s1,72(sp)
    80003f80:	6906                	ld	s2,64(sp)
    80003f82:	79e2                	ld	s3,56(sp)
    80003f84:	7a42                	ld	s4,48(sp)
    80003f86:	7aa2                	ld	s5,40(sp)
    80003f88:	7b02                	ld	s6,32(sp)
    80003f8a:	6be2                	ld	s7,24(sp)
    80003f8c:	6c42                	ld	s8,16(sp)
    80003f8e:	6ca2                	ld	s9,8(sp)
    80003f90:	6125                	addi	sp,sp,96
    80003f92:	8082                	ret
      iunlock(ip);
    80003f94:	854e                	mv	a0,s3
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	aa6080e7          	jalr	-1370(ra) # 80003a3c <iunlock>
      return ip;
    80003f9e:	bfe9                	j	80003f78 <namex+0x6a>
      iunlockput(ip);
    80003fa0:	854e                	mv	a0,s3
    80003fa2:	00000097          	auipc	ra,0x0
    80003fa6:	c3a080e7          	jalr	-966(ra) # 80003bdc <iunlockput>
      return 0;
    80003faa:	89d2                	mv	s3,s4
    80003fac:	b7f1                	j	80003f78 <namex+0x6a>
  len = path - s;
    80003fae:	40b48633          	sub	a2,s1,a1
    80003fb2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fb6:	094cd463          	bge	s9,s4,8000403e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fba:	4639                	li	a2,14
    80003fbc:	8556                	mv	a0,s5
    80003fbe:	ffffd097          	auipc	ra,0xffffd
    80003fc2:	d88080e7          	jalr	-632(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003fc6:	0004c783          	lbu	a5,0(s1)
    80003fca:	01279763          	bne	a5,s2,80003fd8 <namex+0xca>
    path++;
    80003fce:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fd0:	0004c783          	lbu	a5,0(s1)
    80003fd4:	ff278de3          	beq	a5,s2,80003fce <namex+0xc0>
    ilock(ip);
    80003fd8:	854e                	mv	a0,s3
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	9a0080e7          	jalr	-1632(ra) # 8000397a <ilock>
    if(ip->type != T_DIR){
    80003fe2:	04499783          	lh	a5,68(s3)
    80003fe6:	f98793e3          	bne	a5,s8,80003f6c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003fea:	000b0563          	beqz	s6,80003ff4 <namex+0xe6>
    80003fee:	0004c783          	lbu	a5,0(s1)
    80003ff2:	d3cd                	beqz	a5,80003f94 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003ff4:	865e                	mv	a2,s7
    80003ff6:	85d6                	mv	a1,s5
    80003ff8:	854e                	mv	a0,s3
    80003ffa:	00000097          	auipc	ra,0x0
    80003ffe:	e64080e7          	jalr	-412(ra) # 80003e5e <dirlookup>
    80004002:	8a2a                	mv	s4,a0
    80004004:	dd51                	beqz	a0,80003fa0 <namex+0x92>
    iunlockput(ip);
    80004006:	854e                	mv	a0,s3
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	bd4080e7          	jalr	-1068(ra) # 80003bdc <iunlockput>
    ip = next;
    80004010:	89d2                	mv	s3,s4
  while(*path == '/')
    80004012:	0004c783          	lbu	a5,0(s1)
    80004016:	05279763          	bne	a5,s2,80004064 <namex+0x156>
    path++;
    8000401a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000401c:	0004c783          	lbu	a5,0(s1)
    80004020:	ff278de3          	beq	a5,s2,8000401a <namex+0x10c>
  if(*path == 0)
    80004024:	c79d                	beqz	a5,80004052 <namex+0x144>
    path++;
    80004026:	85a6                	mv	a1,s1
  len = path - s;
    80004028:	8a5e                	mv	s4,s7
    8000402a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000402c:	01278963          	beq	a5,s2,8000403e <namex+0x130>
    80004030:	dfbd                	beqz	a5,80003fae <namex+0xa0>
    path++;
    80004032:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004034:	0004c783          	lbu	a5,0(s1)
    80004038:	ff279ce3          	bne	a5,s2,80004030 <namex+0x122>
    8000403c:	bf8d                	j	80003fae <namex+0xa0>
    memmove(name, s, len);
    8000403e:	2601                	sext.w	a2,a2
    80004040:	8556                	mv	a0,s5
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	d04080e7          	jalr	-764(ra) # 80000d46 <memmove>
    name[len] = 0;
    8000404a:	9a56                	add	s4,s4,s5
    8000404c:	000a0023          	sb	zero,0(s4)
    80004050:	bf9d                	j	80003fc6 <namex+0xb8>
  if(nameiparent){
    80004052:	f20b03e3          	beqz	s6,80003f78 <namex+0x6a>
    iput(ip);
    80004056:	854e                	mv	a0,s3
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	adc080e7          	jalr	-1316(ra) # 80003b34 <iput>
    return 0;
    80004060:	4981                	li	s3,0
    80004062:	bf19                	j	80003f78 <namex+0x6a>
  if(*path == 0)
    80004064:	d7fd                	beqz	a5,80004052 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004066:	0004c783          	lbu	a5,0(s1)
    8000406a:	85a6                	mv	a1,s1
    8000406c:	b7d1                	j	80004030 <namex+0x122>

000000008000406e <dirlink>:
{
    8000406e:	7139                	addi	sp,sp,-64
    80004070:	fc06                	sd	ra,56(sp)
    80004072:	f822                	sd	s0,48(sp)
    80004074:	f426                	sd	s1,40(sp)
    80004076:	f04a                	sd	s2,32(sp)
    80004078:	ec4e                	sd	s3,24(sp)
    8000407a:	e852                	sd	s4,16(sp)
    8000407c:	0080                	addi	s0,sp,64
    8000407e:	892a                	mv	s2,a0
    80004080:	8a2e                	mv	s4,a1
    80004082:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004084:	4601                	li	a2,0
    80004086:	00000097          	auipc	ra,0x0
    8000408a:	dd8080e7          	jalr	-552(ra) # 80003e5e <dirlookup>
    8000408e:	e93d                	bnez	a0,80004104 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004090:	04c92483          	lw	s1,76(s2)
    80004094:	c49d                	beqz	s1,800040c2 <dirlink+0x54>
    80004096:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004098:	4741                	li	a4,16
    8000409a:	86a6                	mv	a3,s1
    8000409c:	fc040613          	addi	a2,s0,-64
    800040a0:	4581                	li	a1,0
    800040a2:	854a                	mv	a0,s2
    800040a4:	00000097          	auipc	ra,0x0
    800040a8:	b8a080e7          	jalr	-1142(ra) # 80003c2e <readi>
    800040ac:	47c1                	li	a5,16
    800040ae:	06f51163          	bne	a0,a5,80004110 <dirlink+0xa2>
    if(de.inum == 0)
    800040b2:	fc045783          	lhu	a5,-64(s0)
    800040b6:	c791                	beqz	a5,800040c2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040b8:	24c1                	addiw	s1,s1,16
    800040ba:	04c92783          	lw	a5,76(s2)
    800040be:	fcf4ede3          	bltu	s1,a5,80004098 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040c2:	4639                	li	a2,14
    800040c4:	85d2                	mv	a1,s4
    800040c6:	fc240513          	addi	a0,s0,-62
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	d30080e7          	jalr	-720(ra) # 80000dfa <strncpy>
  de.inum = inum;
    800040d2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d6:	4741                	li	a4,16
    800040d8:	86a6                	mv	a3,s1
    800040da:	fc040613          	addi	a2,s0,-64
    800040de:	4581                	li	a1,0
    800040e0:	854a                	mv	a0,s2
    800040e2:	00000097          	auipc	ra,0x0
    800040e6:	c44080e7          	jalr	-956(ra) # 80003d26 <writei>
    800040ea:	1541                	addi	a0,a0,-16
    800040ec:	00a03533          	snez	a0,a0
    800040f0:	40a00533          	neg	a0,a0
}
    800040f4:	70e2                	ld	ra,56(sp)
    800040f6:	7442                	ld	s0,48(sp)
    800040f8:	74a2                	ld	s1,40(sp)
    800040fa:	7902                	ld	s2,32(sp)
    800040fc:	69e2                	ld	s3,24(sp)
    800040fe:	6a42                	ld	s4,16(sp)
    80004100:	6121                	addi	sp,sp,64
    80004102:	8082                	ret
    iput(ip);
    80004104:	00000097          	auipc	ra,0x0
    80004108:	a30080e7          	jalr	-1488(ra) # 80003b34 <iput>
    return -1;
    8000410c:	557d                	li	a0,-1
    8000410e:	b7dd                	j	800040f4 <dirlink+0x86>
      panic("dirlink read");
    80004110:	00004517          	auipc	a0,0x4
    80004114:	51850513          	addi	a0,a0,1304 # 80008628 <syscalls+0x1d8>
    80004118:	ffffc097          	auipc	ra,0xffffc
    8000411c:	42c080e7          	jalr	1068(ra) # 80000544 <panic>

0000000080004120 <namei>:

struct inode*
namei(char *path)
{
    80004120:	1101                	addi	sp,sp,-32
    80004122:	ec06                	sd	ra,24(sp)
    80004124:	e822                	sd	s0,16(sp)
    80004126:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004128:	fe040613          	addi	a2,s0,-32
    8000412c:	4581                	li	a1,0
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	de0080e7          	jalr	-544(ra) # 80003f0e <namex>
}
    80004136:	60e2                	ld	ra,24(sp)
    80004138:	6442                	ld	s0,16(sp)
    8000413a:	6105                	addi	sp,sp,32
    8000413c:	8082                	ret

000000008000413e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000413e:	1141                	addi	sp,sp,-16
    80004140:	e406                	sd	ra,8(sp)
    80004142:	e022                	sd	s0,0(sp)
    80004144:	0800                	addi	s0,sp,16
    80004146:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004148:	4585                	li	a1,1
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	dc4080e7          	jalr	-572(ra) # 80003f0e <namex>
}
    80004152:	60a2                	ld	ra,8(sp)
    80004154:	6402                	ld	s0,0(sp)
    80004156:	0141                	addi	sp,sp,16
    80004158:	8082                	ret

000000008000415a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000415a:	1101                	addi	sp,sp,-32
    8000415c:	ec06                	sd	ra,24(sp)
    8000415e:	e822                	sd	s0,16(sp)
    80004160:	e426                	sd	s1,8(sp)
    80004162:	e04a                	sd	s2,0(sp)
    80004164:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004166:	0001d917          	auipc	s2,0x1d
    8000416a:	9aa90913          	addi	s2,s2,-1622 # 80020b10 <log>
    8000416e:	01892583          	lw	a1,24(s2)
    80004172:	02892503          	lw	a0,40(s2)
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	fea080e7          	jalr	-22(ra) # 80003160 <bread>
    8000417e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004180:	02c92683          	lw	a3,44(s2)
    80004184:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004186:	02d05763          	blez	a3,800041b4 <write_head+0x5a>
    8000418a:	0001d797          	auipc	a5,0x1d
    8000418e:	9b678793          	addi	a5,a5,-1610 # 80020b40 <log+0x30>
    80004192:	05c50713          	addi	a4,a0,92
    80004196:	36fd                	addiw	a3,a3,-1
    80004198:	1682                	slli	a3,a3,0x20
    8000419a:	9281                	srli	a3,a3,0x20
    8000419c:	068a                	slli	a3,a3,0x2
    8000419e:	0001d617          	auipc	a2,0x1d
    800041a2:	9a660613          	addi	a2,a2,-1626 # 80020b44 <log+0x34>
    800041a6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041a8:	4390                	lw	a2,0(a5)
    800041aa:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041ac:	0791                	addi	a5,a5,4
    800041ae:	0711                	addi	a4,a4,4
    800041b0:	fed79ce3          	bne	a5,a3,800041a8 <write_head+0x4e>
  }
  bwrite(buf);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	09c080e7          	jalr	156(ra) # 80003252 <bwrite>
  brelse(buf);
    800041be:	8526                	mv	a0,s1
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	0d0080e7          	jalr	208(ra) # 80003290 <brelse>
}
    800041c8:	60e2                	ld	ra,24(sp)
    800041ca:	6442                	ld	s0,16(sp)
    800041cc:	64a2                	ld	s1,8(sp)
    800041ce:	6902                	ld	s2,0(sp)
    800041d0:	6105                	addi	sp,sp,32
    800041d2:	8082                	ret

00000000800041d4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d4:	0001d797          	auipc	a5,0x1d
    800041d8:	9687a783          	lw	a5,-1688(a5) # 80020b3c <log+0x2c>
    800041dc:	0af05d63          	blez	a5,80004296 <install_trans+0xc2>
{
    800041e0:	7139                	addi	sp,sp,-64
    800041e2:	fc06                	sd	ra,56(sp)
    800041e4:	f822                	sd	s0,48(sp)
    800041e6:	f426                	sd	s1,40(sp)
    800041e8:	f04a                	sd	s2,32(sp)
    800041ea:	ec4e                	sd	s3,24(sp)
    800041ec:	e852                	sd	s4,16(sp)
    800041ee:	e456                	sd	s5,8(sp)
    800041f0:	e05a                	sd	s6,0(sp)
    800041f2:	0080                	addi	s0,sp,64
    800041f4:	8b2a                	mv	s6,a0
    800041f6:	0001da97          	auipc	s5,0x1d
    800041fa:	94aa8a93          	addi	s5,s5,-1718 # 80020b40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041fe:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004200:	0001d997          	auipc	s3,0x1d
    80004204:	91098993          	addi	s3,s3,-1776 # 80020b10 <log>
    80004208:	a035                	j	80004234 <install_trans+0x60>
      bunpin(dbuf);
    8000420a:	8526                	mv	a0,s1
    8000420c:	fffff097          	auipc	ra,0xfffff
    80004210:	15e080e7          	jalr	350(ra) # 8000336a <bunpin>
    brelse(lbuf);
    80004214:	854a                	mv	a0,s2
    80004216:	fffff097          	auipc	ra,0xfffff
    8000421a:	07a080e7          	jalr	122(ra) # 80003290 <brelse>
    brelse(dbuf);
    8000421e:	8526                	mv	a0,s1
    80004220:	fffff097          	auipc	ra,0xfffff
    80004224:	070080e7          	jalr	112(ra) # 80003290 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004228:	2a05                	addiw	s4,s4,1
    8000422a:	0a91                	addi	s5,s5,4
    8000422c:	02c9a783          	lw	a5,44(s3)
    80004230:	04fa5963          	bge	s4,a5,80004282 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004234:	0189a583          	lw	a1,24(s3)
    80004238:	014585bb          	addw	a1,a1,s4
    8000423c:	2585                	addiw	a1,a1,1
    8000423e:	0289a503          	lw	a0,40(s3)
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	f1e080e7          	jalr	-226(ra) # 80003160 <bread>
    8000424a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000424c:	000aa583          	lw	a1,0(s5)
    80004250:	0289a503          	lw	a0,40(s3)
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	f0c080e7          	jalr	-244(ra) # 80003160 <bread>
    8000425c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000425e:	40000613          	li	a2,1024
    80004262:	05890593          	addi	a1,s2,88
    80004266:	05850513          	addi	a0,a0,88
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	adc080e7          	jalr	-1316(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004272:	8526                	mv	a0,s1
    80004274:	fffff097          	auipc	ra,0xfffff
    80004278:	fde080e7          	jalr	-34(ra) # 80003252 <bwrite>
    if(recovering == 0)
    8000427c:	f80b1ce3          	bnez	s6,80004214 <install_trans+0x40>
    80004280:	b769                	j	8000420a <install_trans+0x36>
}
    80004282:	70e2                	ld	ra,56(sp)
    80004284:	7442                	ld	s0,48(sp)
    80004286:	74a2                	ld	s1,40(sp)
    80004288:	7902                	ld	s2,32(sp)
    8000428a:	69e2                	ld	s3,24(sp)
    8000428c:	6a42                	ld	s4,16(sp)
    8000428e:	6aa2                	ld	s5,8(sp)
    80004290:	6b02                	ld	s6,0(sp)
    80004292:	6121                	addi	sp,sp,64
    80004294:	8082                	ret
    80004296:	8082                	ret

0000000080004298 <initlog>:
{
    80004298:	7179                	addi	sp,sp,-48
    8000429a:	f406                	sd	ra,40(sp)
    8000429c:	f022                	sd	s0,32(sp)
    8000429e:	ec26                	sd	s1,24(sp)
    800042a0:	e84a                	sd	s2,16(sp)
    800042a2:	e44e                	sd	s3,8(sp)
    800042a4:	1800                	addi	s0,sp,48
    800042a6:	892a                	mv	s2,a0
    800042a8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042aa:	0001d497          	auipc	s1,0x1d
    800042ae:	86648493          	addi	s1,s1,-1946 # 80020b10 <log>
    800042b2:	00004597          	auipc	a1,0x4
    800042b6:	38658593          	addi	a1,a1,902 # 80008638 <syscalls+0x1e8>
    800042ba:	8526                	mv	a0,s1
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	89e080e7          	jalr	-1890(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    800042c4:	0149a583          	lw	a1,20(s3)
    800042c8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800042ca:	0109a783          	lw	a5,16(s3)
    800042ce:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800042d0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800042d4:	854a                	mv	a0,s2
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	e8a080e7          	jalr	-374(ra) # 80003160 <bread>
  log.lh.n = lh->n;
    800042de:	4d3c                	lw	a5,88(a0)
    800042e0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800042e2:	02f05563          	blez	a5,8000430c <initlog+0x74>
    800042e6:	05c50713          	addi	a4,a0,92
    800042ea:	0001d697          	auipc	a3,0x1d
    800042ee:	85668693          	addi	a3,a3,-1962 # 80020b40 <log+0x30>
    800042f2:	37fd                	addiw	a5,a5,-1
    800042f4:	1782                	slli	a5,a5,0x20
    800042f6:	9381                	srli	a5,a5,0x20
    800042f8:	078a                	slli	a5,a5,0x2
    800042fa:	06050613          	addi	a2,a0,96
    800042fe:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004300:	4310                	lw	a2,0(a4)
    80004302:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004304:	0711                	addi	a4,a4,4
    80004306:	0691                	addi	a3,a3,4
    80004308:	fef71ce3          	bne	a4,a5,80004300 <initlog+0x68>
  brelse(buf);
    8000430c:	fffff097          	auipc	ra,0xfffff
    80004310:	f84080e7          	jalr	-124(ra) # 80003290 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004314:	4505                	li	a0,1
    80004316:	00000097          	auipc	ra,0x0
    8000431a:	ebe080e7          	jalr	-322(ra) # 800041d4 <install_trans>
  log.lh.n = 0;
    8000431e:	0001d797          	auipc	a5,0x1d
    80004322:	8007af23          	sw	zero,-2018(a5) # 80020b3c <log+0x2c>
  write_head(); // clear the log
    80004326:	00000097          	auipc	ra,0x0
    8000432a:	e34080e7          	jalr	-460(ra) # 8000415a <write_head>
}
    8000432e:	70a2                	ld	ra,40(sp)
    80004330:	7402                	ld	s0,32(sp)
    80004332:	64e2                	ld	s1,24(sp)
    80004334:	6942                	ld	s2,16(sp)
    80004336:	69a2                	ld	s3,8(sp)
    80004338:	6145                	addi	sp,sp,48
    8000433a:	8082                	ret

000000008000433c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000433c:	1101                	addi	sp,sp,-32
    8000433e:	ec06                	sd	ra,24(sp)
    80004340:	e822                	sd	s0,16(sp)
    80004342:	e426                	sd	s1,8(sp)
    80004344:	e04a                	sd	s2,0(sp)
    80004346:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004348:	0001c517          	auipc	a0,0x1c
    8000434c:	7c850513          	addi	a0,a0,1992 # 80020b10 <log>
    80004350:	ffffd097          	auipc	ra,0xffffd
    80004354:	89a080e7          	jalr	-1894(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004358:	0001c497          	auipc	s1,0x1c
    8000435c:	7b848493          	addi	s1,s1,1976 # 80020b10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004360:	4979                	li	s2,30
    80004362:	a039                	j	80004370 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004364:	85a6                	mv	a1,s1
    80004366:	8526                	mv	a0,s1
    80004368:	ffffe097          	auipc	ra,0xffffe
    8000436c:	d02080e7          	jalr	-766(ra) # 8000206a <sleep>
    if(log.committing){
    80004370:	50dc                	lw	a5,36(s1)
    80004372:	fbed                	bnez	a5,80004364 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004374:	509c                	lw	a5,32(s1)
    80004376:	0017871b          	addiw	a4,a5,1
    8000437a:	0007069b          	sext.w	a3,a4
    8000437e:	0027179b          	slliw	a5,a4,0x2
    80004382:	9fb9                	addw	a5,a5,a4
    80004384:	0017979b          	slliw	a5,a5,0x1
    80004388:	54d8                	lw	a4,44(s1)
    8000438a:	9fb9                	addw	a5,a5,a4
    8000438c:	00f95963          	bge	s2,a5,8000439e <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004390:	85a6                	mv	a1,s1
    80004392:	8526                	mv	a0,s1
    80004394:	ffffe097          	auipc	ra,0xffffe
    80004398:	cd6080e7          	jalr	-810(ra) # 8000206a <sleep>
    8000439c:	bfd1                	j	80004370 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000439e:	0001c517          	auipc	a0,0x1c
    800043a2:	77250513          	addi	a0,a0,1906 # 80020b10 <log>
    800043a6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043a8:	ffffd097          	auipc	ra,0xffffd
    800043ac:	8f6080e7          	jalr	-1802(ra) # 80000c9e <release>
      break;
    }
  }
}
    800043b0:	60e2                	ld	ra,24(sp)
    800043b2:	6442                	ld	s0,16(sp)
    800043b4:	64a2                	ld	s1,8(sp)
    800043b6:	6902                	ld	s2,0(sp)
    800043b8:	6105                	addi	sp,sp,32
    800043ba:	8082                	ret

00000000800043bc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043bc:	7139                	addi	sp,sp,-64
    800043be:	fc06                	sd	ra,56(sp)
    800043c0:	f822                	sd	s0,48(sp)
    800043c2:	f426                	sd	s1,40(sp)
    800043c4:	f04a                	sd	s2,32(sp)
    800043c6:	ec4e                	sd	s3,24(sp)
    800043c8:	e852                	sd	s4,16(sp)
    800043ca:	e456                	sd	s5,8(sp)
    800043cc:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800043ce:	0001c497          	auipc	s1,0x1c
    800043d2:	74248493          	addi	s1,s1,1858 # 80020b10 <log>
    800043d6:	8526                	mv	a0,s1
    800043d8:	ffffd097          	auipc	ra,0xffffd
    800043dc:	812080e7          	jalr	-2030(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800043e0:	509c                	lw	a5,32(s1)
    800043e2:	37fd                	addiw	a5,a5,-1
    800043e4:	0007891b          	sext.w	s2,a5
    800043e8:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800043ea:	50dc                	lw	a5,36(s1)
    800043ec:	efb9                	bnez	a5,8000444a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800043ee:	06091663          	bnez	s2,8000445a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800043f2:	0001c497          	auipc	s1,0x1c
    800043f6:	71e48493          	addi	s1,s1,1822 # 80020b10 <log>
    800043fa:	4785                	li	a5,1
    800043fc:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043fe:	8526                	mv	a0,s1
    80004400:	ffffd097          	auipc	ra,0xffffd
    80004404:	89e080e7          	jalr	-1890(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004408:	54dc                	lw	a5,44(s1)
    8000440a:	06f04763          	bgtz	a5,80004478 <end_op+0xbc>
    acquire(&log.lock);
    8000440e:	0001c497          	auipc	s1,0x1c
    80004412:	70248493          	addi	s1,s1,1794 # 80020b10 <log>
    80004416:	8526                	mv	a0,s1
    80004418:	ffffc097          	auipc	ra,0xffffc
    8000441c:	7d2080e7          	jalr	2002(ra) # 80000bea <acquire>
    log.committing = 0;
    80004420:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004424:	8526                	mv	a0,s1
    80004426:	ffffe097          	auipc	ra,0xffffe
    8000442a:	ca8080e7          	jalr	-856(ra) # 800020ce <wakeup>
    release(&log.lock);
    8000442e:	8526                	mv	a0,s1
    80004430:	ffffd097          	auipc	ra,0xffffd
    80004434:	86e080e7          	jalr	-1938(ra) # 80000c9e <release>
}
    80004438:	70e2                	ld	ra,56(sp)
    8000443a:	7442                	ld	s0,48(sp)
    8000443c:	74a2                	ld	s1,40(sp)
    8000443e:	7902                	ld	s2,32(sp)
    80004440:	69e2                	ld	s3,24(sp)
    80004442:	6a42                	ld	s4,16(sp)
    80004444:	6aa2                	ld	s5,8(sp)
    80004446:	6121                	addi	sp,sp,64
    80004448:	8082                	ret
    panic("log.committing");
    8000444a:	00004517          	auipc	a0,0x4
    8000444e:	1f650513          	addi	a0,a0,502 # 80008640 <syscalls+0x1f0>
    80004452:	ffffc097          	auipc	ra,0xffffc
    80004456:	0f2080e7          	jalr	242(ra) # 80000544 <panic>
    wakeup(&log);
    8000445a:	0001c497          	auipc	s1,0x1c
    8000445e:	6b648493          	addi	s1,s1,1718 # 80020b10 <log>
    80004462:	8526                	mv	a0,s1
    80004464:	ffffe097          	auipc	ra,0xffffe
    80004468:	c6a080e7          	jalr	-918(ra) # 800020ce <wakeup>
  release(&log.lock);
    8000446c:	8526                	mv	a0,s1
    8000446e:	ffffd097          	auipc	ra,0xffffd
    80004472:	830080e7          	jalr	-2000(ra) # 80000c9e <release>
  if(do_commit){
    80004476:	b7c9                	j	80004438 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004478:	0001ca97          	auipc	s5,0x1c
    8000447c:	6c8a8a93          	addi	s5,s5,1736 # 80020b40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004480:	0001ca17          	auipc	s4,0x1c
    80004484:	690a0a13          	addi	s4,s4,1680 # 80020b10 <log>
    80004488:	018a2583          	lw	a1,24(s4)
    8000448c:	012585bb          	addw	a1,a1,s2
    80004490:	2585                	addiw	a1,a1,1
    80004492:	028a2503          	lw	a0,40(s4)
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	cca080e7          	jalr	-822(ra) # 80003160 <bread>
    8000449e:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044a0:	000aa583          	lw	a1,0(s5)
    800044a4:	028a2503          	lw	a0,40(s4)
    800044a8:	fffff097          	auipc	ra,0xfffff
    800044ac:	cb8080e7          	jalr	-840(ra) # 80003160 <bread>
    800044b0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044b2:	40000613          	li	a2,1024
    800044b6:	05850593          	addi	a1,a0,88
    800044ba:	05848513          	addi	a0,s1,88
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	888080e7          	jalr	-1912(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800044c6:	8526                	mv	a0,s1
    800044c8:	fffff097          	auipc	ra,0xfffff
    800044cc:	d8a080e7          	jalr	-630(ra) # 80003252 <bwrite>
    brelse(from);
    800044d0:	854e                	mv	a0,s3
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	dbe080e7          	jalr	-578(ra) # 80003290 <brelse>
    brelse(to);
    800044da:	8526                	mv	a0,s1
    800044dc:	fffff097          	auipc	ra,0xfffff
    800044e0:	db4080e7          	jalr	-588(ra) # 80003290 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e4:	2905                	addiw	s2,s2,1
    800044e6:	0a91                	addi	s5,s5,4
    800044e8:	02ca2783          	lw	a5,44(s4)
    800044ec:	f8f94ee3          	blt	s2,a5,80004488 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800044f0:	00000097          	auipc	ra,0x0
    800044f4:	c6a080e7          	jalr	-918(ra) # 8000415a <write_head>
    install_trans(0); // Now install writes to home locations
    800044f8:	4501                	li	a0,0
    800044fa:	00000097          	auipc	ra,0x0
    800044fe:	cda080e7          	jalr	-806(ra) # 800041d4 <install_trans>
    log.lh.n = 0;
    80004502:	0001c797          	auipc	a5,0x1c
    80004506:	6207ad23          	sw	zero,1594(a5) # 80020b3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000450a:	00000097          	auipc	ra,0x0
    8000450e:	c50080e7          	jalr	-944(ra) # 8000415a <write_head>
    80004512:	bdf5                	j	8000440e <end_op+0x52>

0000000080004514 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004514:	1101                	addi	sp,sp,-32
    80004516:	ec06                	sd	ra,24(sp)
    80004518:	e822                	sd	s0,16(sp)
    8000451a:	e426                	sd	s1,8(sp)
    8000451c:	e04a                	sd	s2,0(sp)
    8000451e:	1000                	addi	s0,sp,32
    80004520:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004522:	0001c917          	auipc	s2,0x1c
    80004526:	5ee90913          	addi	s2,s2,1518 # 80020b10 <log>
    8000452a:	854a                	mv	a0,s2
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	6be080e7          	jalr	1726(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004534:	02c92603          	lw	a2,44(s2)
    80004538:	47f5                	li	a5,29
    8000453a:	06c7c563          	blt	a5,a2,800045a4 <log_write+0x90>
    8000453e:	0001c797          	auipc	a5,0x1c
    80004542:	5ee7a783          	lw	a5,1518(a5) # 80020b2c <log+0x1c>
    80004546:	37fd                	addiw	a5,a5,-1
    80004548:	04f65e63          	bge	a2,a5,800045a4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000454c:	0001c797          	auipc	a5,0x1c
    80004550:	5e47a783          	lw	a5,1508(a5) # 80020b30 <log+0x20>
    80004554:	06f05063          	blez	a5,800045b4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004558:	4781                	li	a5,0
    8000455a:	06c05563          	blez	a2,800045c4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000455e:	44cc                	lw	a1,12(s1)
    80004560:	0001c717          	auipc	a4,0x1c
    80004564:	5e070713          	addi	a4,a4,1504 # 80020b40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004568:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000456a:	4314                	lw	a3,0(a4)
    8000456c:	04b68c63          	beq	a3,a1,800045c4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004570:	2785                	addiw	a5,a5,1
    80004572:	0711                	addi	a4,a4,4
    80004574:	fef61be3          	bne	a2,a5,8000456a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004578:	0621                	addi	a2,a2,8
    8000457a:	060a                	slli	a2,a2,0x2
    8000457c:	0001c797          	auipc	a5,0x1c
    80004580:	59478793          	addi	a5,a5,1428 # 80020b10 <log>
    80004584:	963e                	add	a2,a2,a5
    80004586:	44dc                	lw	a5,12(s1)
    80004588:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000458a:	8526                	mv	a0,s1
    8000458c:	fffff097          	auipc	ra,0xfffff
    80004590:	da2080e7          	jalr	-606(ra) # 8000332e <bpin>
    log.lh.n++;
    80004594:	0001c717          	auipc	a4,0x1c
    80004598:	57c70713          	addi	a4,a4,1404 # 80020b10 <log>
    8000459c:	575c                	lw	a5,44(a4)
    8000459e:	2785                	addiw	a5,a5,1
    800045a0:	d75c                	sw	a5,44(a4)
    800045a2:	a835                	j	800045de <log_write+0xca>
    panic("too big a transaction");
    800045a4:	00004517          	auipc	a0,0x4
    800045a8:	0ac50513          	addi	a0,a0,172 # 80008650 <syscalls+0x200>
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	f98080e7          	jalr	-104(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800045b4:	00004517          	auipc	a0,0x4
    800045b8:	0b450513          	addi	a0,a0,180 # 80008668 <syscalls+0x218>
    800045bc:	ffffc097          	auipc	ra,0xffffc
    800045c0:	f88080e7          	jalr	-120(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800045c4:	00878713          	addi	a4,a5,8
    800045c8:	00271693          	slli	a3,a4,0x2
    800045cc:	0001c717          	auipc	a4,0x1c
    800045d0:	54470713          	addi	a4,a4,1348 # 80020b10 <log>
    800045d4:	9736                	add	a4,a4,a3
    800045d6:	44d4                	lw	a3,12(s1)
    800045d8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800045da:	faf608e3          	beq	a2,a5,8000458a <log_write+0x76>
  }
  release(&log.lock);
    800045de:	0001c517          	auipc	a0,0x1c
    800045e2:	53250513          	addi	a0,a0,1330 # 80020b10 <log>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6b8080e7          	jalr	1720(ra) # 80000c9e <release>
}
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6902                	ld	s2,0(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045fa:	1101                	addi	sp,sp,-32
    800045fc:	ec06                	sd	ra,24(sp)
    800045fe:	e822                	sd	s0,16(sp)
    80004600:	e426                	sd	s1,8(sp)
    80004602:	e04a                	sd	s2,0(sp)
    80004604:	1000                	addi	s0,sp,32
    80004606:	84aa                	mv	s1,a0
    80004608:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000460a:	00004597          	auipc	a1,0x4
    8000460e:	07e58593          	addi	a1,a1,126 # 80008688 <syscalls+0x238>
    80004612:	0521                	addi	a0,a0,8
    80004614:	ffffc097          	auipc	ra,0xffffc
    80004618:	546080e7          	jalr	1350(ra) # 80000b5a <initlock>
  lk->name = name;
    8000461c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004620:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004624:	0204a423          	sw	zero,40(s1)
}
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6902                	ld	s2,0(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret

0000000080004634 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004634:	1101                	addi	sp,sp,-32
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e822                	sd	s0,16(sp)
    8000463a:	e426                	sd	s1,8(sp)
    8000463c:	e04a                	sd	s2,0(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004642:	00850913          	addi	s2,a0,8
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	5a2080e7          	jalr	1442(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004650:	409c                	lw	a5,0(s1)
    80004652:	cb89                	beqz	a5,80004664 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004654:	85ca                	mv	a1,s2
    80004656:	8526                	mv	a0,s1
    80004658:	ffffe097          	auipc	ra,0xffffe
    8000465c:	a12080e7          	jalr	-1518(ra) # 8000206a <sleep>
  while (lk->locked) {
    80004660:	409c                	lw	a5,0(s1)
    80004662:	fbed                	bnez	a5,80004654 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004664:	4785                	li	a5,1
    80004666:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004668:	ffffd097          	auipc	ra,0xffffd
    8000466c:	35e080e7          	jalr	862(ra) # 800019c6 <myproc>
    80004670:	591c                	lw	a5,48(a0)
    80004672:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004674:	854a                	mv	a0,s2
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	628080e7          	jalr	1576(ra) # 80000c9e <release>
}
    8000467e:	60e2                	ld	ra,24(sp)
    80004680:	6442                	ld	s0,16(sp)
    80004682:	64a2                	ld	s1,8(sp)
    80004684:	6902                	ld	s2,0(sp)
    80004686:	6105                	addi	sp,sp,32
    80004688:	8082                	ret

000000008000468a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000468a:	1101                	addi	sp,sp,-32
    8000468c:	ec06                	sd	ra,24(sp)
    8000468e:	e822                	sd	s0,16(sp)
    80004690:	e426                	sd	s1,8(sp)
    80004692:	e04a                	sd	s2,0(sp)
    80004694:	1000                	addi	s0,sp,32
    80004696:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004698:	00850913          	addi	s2,a0,8
    8000469c:	854a                	mv	a0,s2
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	54c080e7          	jalr	1356(ra) # 80000bea <acquire>
  lk->locked = 0;
    800046a6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046aa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046ae:	8526                	mv	a0,s1
    800046b0:	ffffe097          	auipc	ra,0xffffe
    800046b4:	a1e080e7          	jalr	-1506(ra) # 800020ce <wakeup>
  release(&lk->lk);
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	5e4080e7          	jalr	1508(ra) # 80000c9e <release>
}
    800046c2:	60e2                	ld	ra,24(sp)
    800046c4:	6442                	ld	s0,16(sp)
    800046c6:	64a2                	ld	s1,8(sp)
    800046c8:	6902                	ld	s2,0(sp)
    800046ca:	6105                	addi	sp,sp,32
    800046cc:	8082                	ret

00000000800046ce <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800046ce:	7179                	addi	sp,sp,-48
    800046d0:	f406                	sd	ra,40(sp)
    800046d2:	f022                	sd	s0,32(sp)
    800046d4:	ec26                	sd	s1,24(sp)
    800046d6:	e84a                	sd	s2,16(sp)
    800046d8:	e44e                	sd	s3,8(sp)
    800046da:	1800                	addi	s0,sp,48
    800046dc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800046de:	00850913          	addi	s2,a0,8
    800046e2:	854a                	mv	a0,s2
    800046e4:	ffffc097          	auipc	ra,0xffffc
    800046e8:	506080e7          	jalr	1286(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	ef99                	bnez	a5,8000470c <holdingsleep+0x3e>
    800046f0:	4481                	li	s1,0
  release(&lk->lk);
    800046f2:	854a                	mv	a0,s2
    800046f4:	ffffc097          	auipc	ra,0xffffc
    800046f8:	5aa080e7          	jalr	1450(ra) # 80000c9e <release>
  return r;
}
    800046fc:	8526                	mv	a0,s1
    800046fe:	70a2                	ld	ra,40(sp)
    80004700:	7402                	ld	s0,32(sp)
    80004702:	64e2                	ld	s1,24(sp)
    80004704:	6942                	ld	s2,16(sp)
    80004706:	69a2                	ld	s3,8(sp)
    80004708:	6145                	addi	sp,sp,48
    8000470a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000470c:	0284a983          	lw	s3,40(s1)
    80004710:	ffffd097          	auipc	ra,0xffffd
    80004714:	2b6080e7          	jalr	694(ra) # 800019c6 <myproc>
    80004718:	5904                	lw	s1,48(a0)
    8000471a:	413484b3          	sub	s1,s1,s3
    8000471e:	0014b493          	seqz	s1,s1
    80004722:	bfc1                	j	800046f2 <holdingsleep+0x24>

0000000080004724 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004724:	1141                	addi	sp,sp,-16
    80004726:	e406                	sd	ra,8(sp)
    80004728:	e022                	sd	s0,0(sp)
    8000472a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000472c:	00004597          	auipc	a1,0x4
    80004730:	f6c58593          	addi	a1,a1,-148 # 80008698 <syscalls+0x248>
    80004734:	0001c517          	auipc	a0,0x1c
    80004738:	52450513          	addi	a0,a0,1316 # 80020c58 <ftable>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	41e080e7          	jalr	1054(ra) # 80000b5a <initlock>
}
    80004744:	60a2                	ld	ra,8(sp)
    80004746:	6402                	ld	s0,0(sp)
    80004748:	0141                	addi	sp,sp,16
    8000474a:	8082                	ret

000000008000474c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000474c:	1101                	addi	sp,sp,-32
    8000474e:	ec06                	sd	ra,24(sp)
    80004750:	e822                	sd	s0,16(sp)
    80004752:	e426                	sd	s1,8(sp)
    80004754:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004756:	0001c517          	auipc	a0,0x1c
    8000475a:	50250513          	addi	a0,a0,1282 # 80020c58 <ftable>
    8000475e:	ffffc097          	auipc	ra,0xffffc
    80004762:	48c080e7          	jalr	1164(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004766:	0001c497          	auipc	s1,0x1c
    8000476a:	50a48493          	addi	s1,s1,1290 # 80020c70 <ftable+0x18>
    8000476e:	0001d717          	auipc	a4,0x1d
    80004772:	4a270713          	addi	a4,a4,1186 # 80021c10 <disk>
    if(f->ref == 0){
    80004776:	40dc                	lw	a5,4(s1)
    80004778:	cf99                	beqz	a5,80004796 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000477a:	02848493          	addi	s1,s1,40
    8000477e:	fee49ce3          	bne	s1,a4,80004776 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004782:	0001c517          	auipc	a0,0x1c
    80004786:	4d650513          	addi	a0,a0,1238 # 80020c58 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	514080e7          	jalr	1300(ra) # 80000c9e <release>
  return 0;
    80004792:	4481                	li	s1,0
    80004794:	a819                	j	800047aa <filealloc+0x5e>
      f->ref = 1;
    80004796:	4785                	li	a5,1
    80004798:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000479a:	0001c517          	auipc	a0,0x1c
    8000479e:	4be50513          	addi	a0,a0,1214 # 80020c58 <ftable>
    800047a2:	ffffc097          	auipc	ra,0xffffc
    800047a6:	4fc080e7          	jalr	1276(ra) # 80000c9e <release>
}
    800047aa:	8526                	mv	a0,s1
    800047ac:	60e2                	ld	ra,24(sp)
    800047ae:	6442                	ld	s0,16(sp)
    800047b0:	64a2                	ld	s1,8(sp)
    800047b2:	6105                	addi	sp,sp,32
    800047b4:	8082                	ret

00000000800047b6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047b6:	1101                	addi	sp,sp,-32
    800047b8:	ec06                	sd	ra,24(sp)
    800047ba:	e822                	sd	s0,16(sp)
    800047bc:	e426                	sd	s1,8(sp)
    800047be:	1000                	addi	s0,sp,32
    800047c0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047c2:	0001c517          	auipc	a0,0x1c
    800047c6:	49650513          	addi	a0,a0,1174 # 80020c58 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	420080e7          	jalr	1056(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800047d2:	40dc                	lw	a5,4(s1)
    800047d4:	02f05263          	blez	a5,800047f8 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800047d8:	2785                	addiw	a5,a5,1
    800047da:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800047dc:	0001c517          	auipc	a0,0x1c
    800047e0:	47c50513          	addi	a0,a0,1148 # 80020c58 <ftable>
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4ba080e7          	jalr	1210(ra) # 80000c9e <release>
  return f;
}
    800047ec:	8526                	mv	a0,s1
    800047ee:	60e2                	ld	ra,24(sp)
    800047f0:	6442                	ld	s0,16(sp)
    800047f2:	64a2                	ld	s1,8(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret
    panic("filedup");
    800047f8:	00004517          	auipc	a0,0x4
    800047fc:	ea850513          	addi	a0,a0,-344 # 800086a0 <syscalls+0x250>
    80004800:	ffffc097          	auipc	ra,0xffffc
    80004804:	d44080e7          	jalr	-700(ra) # 80000544 <panic>

0000000080004808 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004808:	7139                	addi	sp,sp,-64
    8000480a:	fc06                	sd	ra,56(sp)
    8000480c:	f822                	sd	s0,48(sp)
    8000480e:	f426                	sd	s1,40(sp)
    80004810:	f04a                	sd	s2,32(sp)
    80004812:	ec4e                	sd	s3,24(sp)
    80004814:	e852                	sd	s4,16(sp)
    80004816:	e456                	sd	s5,8(sp)
    80004818:	0080                	addi	s0,sp,64
    8000481a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000481c:	0001c517          	auipc	a0,0x1c
    80004820:	43c50513          	addi	a0,a0,1084 # 80020c58 <ftable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	3c6080e7          	jalr	966(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000482c:	40dc                	lw	a5,4(s1)
    8000482e:	06f05163          	blez	a5,80004890 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004832:	37fd                	addiw	a5,a5,-1
    80004834:	0007871b          	sext.w	a4,a5
    80004838:	c0dc                	sw	a5,4(s1)
    8000483a:	06e04363          	bgtz	a4,800048a0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000483e:	0004a903          	lw	s2,0(s1)
    80004842:	0094ca83          	lbu	s5,9(s1)
    80004846:	0104ba03          	ld	s4,16(s1)
    8000484a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000484e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004852:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004856:	0001c517          	auipc	a0,0x1c
    8000485a:	40250513          	addi	a0,a0,1026 # 80020c58 <ftable>
    8000485e:	ffffc097          	auipc	ra,0xffffc
    80004862:	440080e7          	jalr	1088(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004866:	4785                	li	a5,1
    80004868:	04f90d63          	beq	s2,a5,800048c2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000486c:	3979                	addiw	s2,s2,-2
    8000486e:	4785                	li	a5,1
    80004870:	0527e063          	bltu	a5,s2,800048b0 <fileclose+0xa8>
    begin_op();
    80004874:	00000097          	auipc	ra,0x0
    80004878:	ac8080e7          	jalr	-1336(ra) # 8000433c <begin_op>
    iput(ff.ip);
    8000487c:	854e                	mv	a0,s3
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	2b6080e7          	jalr	694(ra) # 80003b34 <iput>
    end_op();
    80004886:	00000097          	auipc	ra,0x0
    8000488a:	b36080e7          	jalr	-1226(ra) # 800043bc <end_op>
    8000488e:	a00d                	j	800048b0 <fileclose+0xa8>
    panic("fileclose");
    80004890:	00004517          	auipc	a0,0x4
    80004894:	e1850513          	addi	a0,a0,-488 # 800086a8 <syscalls+0x258>
    80004898:	ffffc097          	auipc	ra,0xffffc
    8000489c:	cac080e7          	jalr	-852(ra) # 80000544 <panic>
    release(&ftable.lock);
    800048a0:	0001c517          	auipc	a0,0x1c
    800048a4:	3b850513          	addi	a0,a0,952 # 80020c58 <ftable>
    800048a8:	ffffc097          	auipc	ra,0xffffc
    800048ac:	3f6080e7          	jalr	1014(ra) # 80000c9e <release>
  }
}
    800048b0:	70e2                	ld	ra,56(sp)
    800048b2:	7442                	ld	s0,48(sp)
    800048b4:	74a2                	ld	s1,40(sp)
    800048b6:	7902                	ld	s2,32(sp)
    800048b8:	69e2                	ld	s3,24(sp)
    800048ba:	6a42                	ld	s4,16(sp)
    800048bc:	6aa2                	ld	s5,8(sp)
    800048be:	6121                	addi	sp,sp,64
    800048c0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048c2:	85d6                	mv	a1,s5
    800048c4:	8552                	mv	a0,s4
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	34c080e7          	jalr	844(ra) # 80004c12 <pipeclose>
    800048ce:	b7cd                	j	800048b0 <fileclose+0xa8>

00000000800048d0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800048d0:	715d                	addi	sp,sp,-80
    800048d2:	e486                	sd	ra,72(sp)
    800048d4:	e0a2                	sd	s0,64(sp)
    800048d6:	fc26                	sd	s1,56(sp)
    800048d8:	f84a                	sd	s2,48(sp)
    800048da:	f44e                	sd	s3,40(sp)
    800048dc:	0880                	addi	s0,sp,80
    800048de:	84aa                	mv	s1,a0
    800048e0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800048e2:	ffffd097          	auipc	ra,0xffffd
    800048e6:	0e4080e7          	jalr	228(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800048ea:	409c                	lw	a5,0(s1)
    800048ec:	37f9                	addiw	a5,a5,-2
    800048ee:	4705                	li	a4,1
    800048f0:	04f76763          	bltu	a4,a5,8000493e <filestat+0x6e>
    800048f4:	892a                	mv	s2,a0
    ilock(f->ip);
    800048f6:	6c88                	ld	a0,24(s1)
    800048f8:	fffff097          	auipc	ra,0xfffff
    800048fc:	082080e7          	jalr	130(ra) # 8000397a <ilock>
    stati(f->ip, &st);
    80004900:	fb840593          	addi	a1,s0,-72
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	2fe080e7          	jalr	766(ra) # 80003c04 <stati>
    iunlock(f->ip);
    8000490e:	6c88                	ld	a0,24(s1)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	12c080e7          	jalr	300(ra) # 80003a3c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004918:	46e1                	li	a3,24
    8000491a:	fb840613          	addi	a2,s0,-72
    8000491e:	85ce                	mv	a1,s3
    80004920:	05093503          	ld	a0,80(s2)
    80004924:	ffffd097          	auipc	ra,0xffffd
    80004928:	d60080e7          	jalr	-672(ra) # 80001684 <copyout>
    8000492c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004930:	60a6                	ld	ra,72(sp)
    80004932:	6406                	ld	s0,64(sp)
    80004934:	74e2                	ld	s1,56(sp)
    80004936:	7942                	ld	s2,48(sp)
    80004938:	79a2                	ld	s3,40(sp)
    8000493a:	6161                	addi	sp,sp,80
    8000493c:	8082                	ret
  return -1;
    8000493e:	557d                	li	a0,-1
    80004940:	bfc5                	j	80004930 <filestat+0x60>

0000000080004942 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004942:	7179                	addi	sp,sp,-48
    80004944:	f406                	sd	ra,40(sp)
    80004946:	f022                	sd	s0,32(sp)
    80004948:	ec26                	sd	s1,24(sp)
    8000494a:	e84a                	sd	s2,16(sp)
    8000494c:	e44e                	sd	s3,8(sp)
    8000494e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004950:	00854783          	lbu	a5,8(a0)
    80004954:	c3d5                	beqz	a5,800049f8 <fileread+0xb6>
    80004956:	84aa                	mv	s1,a0
    80004958:	89ae                	mv	s3,a1
    8000495a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000495c:	411c                	lw	a5,0(a0)
    8000495e:	4705                	li	a4,1
    80004960:	04e78963          	beq	a5,a4,800049b2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004964:	470d                	li	a4,3
    80004966:	04e78d63          	beq	a5,a4,800049c0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000496a:	4709                	li	a4,2
    8000496c:	06e79e63          	bne	a5,a4,800049e8 <fileread+0xa6>
    ilock(f->ip);
    80004970:	6d08                	ld	a0,24(a0)
    80004972:	fffff097          	auipc	ra,0xfffff
    80004976:	008080e7          	jalr	8(ra) # 8000397a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000497a:	874a                	mv	a4,s2
    8000497c:	5094                	lw	a3,32(s1)
    8000497e:	864e                	mv	a2,s3
    80004980:	4585                	li	a1,1
    80004982:	6c88                	ld	a0,24(s1)
    80004984:	fffff097          	auipc	ra,0xfffff
    80004988:	2aa080e7          	jalr	682(ra) # 80003c2e <readi>
    8000498c:	892a                	mv	s2,a0
    8000498e:	00a05563          	blez	a0,80004998 <fileread+0x56>
      f->off += r;
    80004992:	509c                	lw	a5,32(s1)
    80004994:	9fa9                	addw	a5,a5,a0
    80004996:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004998:	6c88                	ld	a0,24(s1)
    8000499a:	fffff097          	auipc	ra,0xfffff
    8000499e:	0a2080e7          	jalr	162(ra) # 80003a3c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049a2:	854a                	mv	a0,s2
    800049a4:	70a2                	ld	ra,40(sp)
    800049a6:	7402                	ld	s0,32(sp)
    800049a8:	64e2                	ld	s1,24(sp)
    800049aa:	6942                	ld	s2,16(sp)
    800049ac:	69a2                	ld	s3,8(sp)
    800049ae:	6145                	addi	sp,sp,48
    800049b0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049b2:	6908                	ld	a0,16(a0)
    800049b4:	00000097          	auipc	ra,0x0
    800049b8:	3ce080e7          	jalr	974(ra) # 80004d82 <piperead>
    800049bc:	892a                	mv	s2,a0
    800049be:	b7d5                	j	800049a2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049c0:	02451783          	lh	a5,36(a0)
    800049c4:	03079693          	slli	a3,a5,0x30
    800049c8:	92c1                	srli	a3,a3,0x30
    800049ca:	4725                	li	a4,9
    800049cc:	02d76863          	bltu	a4,a3,800049fc <fileread+0xba>
    800049d0:	0792                	slli	a5,a5,0x4
    800049d2:	0001c717          	auipc	a4,0x1c
    800049d6:	1e670713          	addi	a4,a4,486 # 80020bb8 <devsw>
    800049da:	97ba                	add	a5,a5,a4
    800049dc:	639c                	ld	a5,0(a5)
    800049de:	c38d                	beqz	a5,80004a00 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800049e0:	4505                	li	a0,1
    800049e2:	9782                	jalr	a5
    800049e4:	892a                	mv	s2,a0
    800049e6:	bf75                	j	800049a2 <fileread+0x60>
    panic("fileread");
    800049e8:	00004517          	auipc	a0,0x4
    800049ec:	cd050513          	addi	a0,a0,-816 # 800086b8 <syscalls+0x268>
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	b54080e7          	jalr	-1196(ra) # 80000544 <panic>
    return -1;
    800049f8:	597d                	li	s2,-1
    800049fa:	b765                	j	800049a2 <fileread+0x60>
      return -1;
    800049fc:	597d                	li	s2,-1
    800049fe:	b755                	j	800049a2 <fileread+0x60>
    80004a00:	597d                	li	s2,-1
    80004a02:	b745                	j	800049a2 <fileread+0x60>

0000000080004a04 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a04:	715d                	addi	sp,sp,-80
    80004a06:	e486                	sd	ra,72(sp)
    80004a08:	e0a2                	sd	s0,64(sp)
    80004a0a:	fc26                	sd	s1,56(sp)
    80004a0c:	f84a                	sd	s2,48(sp)
    80004a0e:	f44e                	sd	s3,40(sp)
    80004a10:	f052                	sd	s4,32(sp)
    80004a12:	ec56                	sd	s5,24(sp)
    80004a14:	e85a                	sd	s6,16(sp)
    80004a16:	e45e                	sd	s7,8(sp)
    80004a18:	e062                	sd	s8,0(sp)
    80004a1a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a1c:	00954783          	lbu	a5,9(a0)
    80004a20:	10078663          	beqz	a5,80004b2c <filewrite+0x128>
    80004a24:	892a                	mv	s2,a0
    80004a26:	8aae                	mv	s5,a1
    80004a28:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a2a:	411c                	lw	a5,0(a0)
    80004a2c:	4705                	li	a4,1
    80004a2e:	02e78263          	beq	a5,a4,80004a52 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a32:	470d                	li	a4,3
    80004a34:	02e78663          	beq	a5,a4,80004a60 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a38:	4709                	li	a4,2
    80004a3a:	0ee79163          	bne	a5,a4,80004b1c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a3e:	0ac05d63          	blez	a2,80004af8 <filewrite+0xf4>
    int i = 0;
    80004a42:	4981                	li	s3,0
    80004a44:	6b05                	lui	s6,0x1
    80004a46:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a4a:	6b85                	lui	s7,0x1
    80004a4c:	c00b8b9b          	addiw	s7,s7,-1024
    80004a50:	a861                	j	80004ae8 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a52:	6908                	ld	a0,16(a0)
    80004a54:	00000097          	auipc	ra,0x0
    80004a58:	22e080e7          	jalr	558(ra) # 80004c82 <pipewrite>
    80004a5c:	8a2a                	mv	s4,a0
    80004a5e:	a045                	j	80004afe <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a60:	02451783          	lh	a5,36(a0)
    80004a64:	03079693          	slli	a3,a5,0x30
    80004a68:	92c1                	srli	a3,a3,0x30
    80004a6a:	4725                	li	a4,9
    80004a6c:	0cd76263          	bltu	a4,a3,80004b30 <filewrite+0x12c>
    80004a70:	0792                	slli	a5,a5,0x4
    80004a72:	0001c717          	auipc	a4,0x1c
    80004a76:	14670713          	addi	a4,a4,326 # 80020bb8 <devsw>
    80004a7a:	97ba                	add	a5,a5,a4
    80004a7c:	679c                	ld	a5,8(a5)
    80004a7e:	cbdd                	beqz	a5,80004b34 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a80:	4505                	li	a0,1
    80004a82:	9782                	jalr	a5
    80004a84:	8a2a                	mv	s4,a0
    80004a86:	a8a5                	j	80004afe <filewrite+0xfa>
    80004a88:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a8c:	00000097          	auipc	ra,0x0
    80004a90:	8b0080e7          	jalr	-1872(ra) # 8000433c <begin_op>
      ilock(f->ip);
    80004a94:	01893503          	ld	a0,24(s2)
    80004a98:	fffff097          	auipc	ra,0xfffff
    80004a9c:	ee2080e7          	jalr	-286(ra) # 8000397a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004aa0:	8762                	mv	a4,s8
    80004aa2:	02092683          	lw	a3,32(s2)
    80004aa6:	01598633          	add	a2,s3,s5
    80004aaa:	4585                	li	a1,1
    80004aac:	01893503          	ld	a0,24(s2)
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	276080e7          	jalr	630(ra) # 80003d26 <writei>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	00a05763          	blez	a0,80004ac8 <filewrite+0xc4>
        f->off += r;
    80004abe:	02092783          	lw	a5,32(s2)
    80004ac2:	9fa9                	addw	a5,a5,a0
    80004ac4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ac8:	01893503          	ld	a0,24(s2)
    80004acc:	fffff097          	auipc	ra,0xfffff
    80004ad0:	f70080e7          	jalr	-144(ra) # 80003a3c <iunlock>
      end_op();
    80004ad4:	00000097          	auipc	ra,0x0
    80004ad8:	8e8080e7          	jalr	-1816(ra) # 800043bc <end_op>

      if(r != n1){
    80004adc:	009c1f63          	bne	s8,s1,80004afa <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004ae0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ae4:	0149db63          	bge	s3,s4,80004afa <filewrite+0xf6>
      int n1 = n - i;
    80004ae8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004aec:	84be                	mv	s1,a5
    80004aee:	2781                	sext.w	a5,a5
    80004af0:	f8fb5ce3          	bge	s6,a5,80004a88 <filewrite+0x84>
    80004af4:	84de                	mv	s1,s7
    80004af6:	bf49                	j	80004a88 <filewrite+0x84>
    int i = 0;
    80004af8:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004afa:	013a1f63          	bne	s4,s3,80004b18 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004afe:	8552                	mv	a0,s4
    80004b00:	60a6                	ld	ra,72(sp)
    80004b02:	6406                	ld	s0,64(sp)
    80004b04:	74e2                	ld	s1,56(sp)
    80004b06:	7942                	ld	s2,48(sp)
    80004b08:	79a2                	ld	s3,40(sp)
    80004b0a:	7a02                	ld	s4,32(sp)
    80004b0c:	6ae2                	ld	s5,24(sp)
    80004b0e:	6b42                	ld	s6,16(sp)
    80004b10:	6ba2                	ld	s7,8(sp)
    80004b12:	6c02                	ld	s8,0(sp)
    80004b14:	6161                	addi	sp,sp,80
    80004b16:	8082                	ret
    ret = (i == n ? n : -1);
    80004b18:	5a7d                	li	s4,-1
    80004b1a:	b7d5                	j	80004afe <filewrite+0xfa>
    panic("filewrite");
    80004b1c:	00004517          	auipc	a0,0x4
    80004b20:	bac50513          	addi	a0,a0,-1108 # 800086c8 <syscalls+0x278>
    80004b24:	ffffc097          	auipc	ra,0xffffc
    80004b28:	a20080e7          	jalr	-1504(ra) # 80000544 <panic>
    return -1;
    80004b2c:	5a7d                	li	s4,-1
    80004b2e:	bfc1                	j	80004afe <filewrite+0xfa>
      return -1;
    80004b30:	5a7d                	li	s4,-1
    80004b32:	b7f1                	j	80004afe <filewrite+0xfa>
    80004b34:	5a7d                	li	s4,-1
    80004b36:	b7e1                	j	80004afe <filewrite+0xfa>

0000000080004b38 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b38:	7179                	addi	sp,sp,-48
    80004b3a:	f406                	sd	ra,40(sp)
    80004b3c:	f022                	sd	s0,32(sp)
    80004b3e:	ec26                	sd	s1,24(sp)
    80004b40:	e84a                	sd	s2,16(sp)
    80004b42:	e44e                	sd	s3,8(sp)
    80004b44:	e052                	sd	s4,0(sp)
    80004b46:	1800                	addi	s0,sp,48
    80004b48:	84aa                	mv	s1,a0
    80004b4a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004b4c:	0005b023          	sd	zero,0(a1)
    80004b50:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004b54:	00000097          	auipc	ra,0x0
    80004b58:	bf8080e7          	jalr	-1032(ra) # 8000474c <filealloc>
    80004b5c:	e088                	sd	a0,0(s1)
    80004b5e:	c551                	beqz	a0,80004bea <pipealloc+0xb2>
    80004b60:	00000097          	auipc	ra,0x0
    80004b64:	bec080e7          	jalr	-1044(ra) # 8000474c <filealloc>
    80004b68:	00aa3023          	sd	a0,0(s4)
    80004b6c:	c92d                	beqz	a0,80004bde <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	f8c080e7          	jalr	-116(ra) # 80000afa <kalloc>
    80004b76:	892a                	mv	s2,a0
    80004b78:	c125                	beqz	a0,80004bd8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b7a:	4985                	li	s3,1
    80004b7c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b80:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b84:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b88:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b8c:	00004597          	auipc	a1,0x4
    80004b90:	b4c58593          	addi	a1,a1,-1204 # 800086d8 <syscalls+0x288>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	fc6080e7          	jalr	-58(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004b9c:	609c                	ld	a5,0(s1)
    80004b9e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ba2:	609c                	ld	a5,0(s1)
    80004ba4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ba8:	609c                	ld	a5,0(s1)
    80004baa:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004bae:	609c                	ld	a5,0(s1)
    80004bb0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004bb4:	000a3783          	ld	a5,0(s4)
    80004bb8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004bbc:	000a3783          	ld	a5,0(s4)
    80004bc0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004bc4:	000a3783          	ld	a5,0(s4)
    80004bc8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004bcc:	000a3783          	ld	a5,0(s4)
    80004bd0:	0127b823          	sd	s2,16(a5)
  return 0;
    80004bd4:	4501                	li	a0,0
    80004bd6:	a025                	j	80004bfe <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004bd8:	6088                	ld	a0,0(s1)
    80004bda:	e501                	bnez	a0,80004be2 <pipealloc+0xaa>
    80004bdc:	a039                	j	80004bea <pipealloc+0xb2>
    80004bde:	6088                	ld	a0,0(s1)
    80004be0:	c51d                	beqz	a0,80004c0e <pipealloc+0xd6>
    fileclose(*f0);
    80004be2:	00000097          	auipc	ra,0x0
    80004be6:	c26080e7          	jalr	-986(ra) # 80004808 <fileclose>
  if(*f1)
    80004bea:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004bee:	557d                	li	a0,-1
  if(*f1)
    80004bf0:	c799                	beqz	a5,80004bfe <pipealloc+0xc6>
    fileclose(*f1);
    80004bf2:	853e                	mv	a0,a5
    80004bf4:	00000097          	auipc	ra,0x0
    80004bf8:	c14080e7          	jalr	-1004(ra) # 80004808 <fileclose>
  return -1;
    80004bfc:	557d                	li	a0,-1
}
    80004bfe:	70a2                	ld	ra,40(sp)
    80004c00:	7402                	ld	s0,32(sp)
    80004c02:	64e2                	ld	s1,24(sp)
    80004c04:	6942                	ld	s2,16(sp)
    80004c06:	69a2                	ld	s3,8(sp)
    80004c08:	6a02                	ld	s4,0(sp)
    80004c0a:	6145                	addi	sp,sp,48
    80004c0c:	8082                	ret
  return -1;
    80004c0e:	557d                	li	a0,-1
    80004c10:	b7fd                	j	80004bfe <pipealloc+0xc6>

0000000080004c12 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c12:	1101                	addi	sp,sp,-32
    80004c14:	ec06                	sd	ra,24(sp)
    80004c16:	e822                	sd	s0,16(sp)
    80004c18:	e426                	sd	s1,8(sp)
    80004c1a:	e04a                	sd	s2,0(sp)
    80004c1c:	1000                	addi	s0,sp,32
    80004c1e:	84aa                	mv	s1,a0
    80004c20:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	fc8080e7          	jalr	-56(ra) # 80000bea <acquire>
  if(writable){
    80004c2a:	02090d63          	beqz	s2,80004c64 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c2e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c32:	21848513          	addi	a0,s1,536
    80004c36:	ffffd097          	auipc	ra,0xffffd
    80004c3a:	498080e7          	jalr	1176(ra) # 800020ce <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004c3e:	2204b783          	ld	a5,544(s1)
    80004c42:	eb95                	bnez	a5,80004c76 <pipeclose+0x64>
    release(&pi->lock);
    80004c44:	8526                	mv	a0,s1
    80004c46:	ffffc097          	auipc	ra,0xffffc
    80004c4a:	058080e7          	jalr	88(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004c4e:	8526                	mv	a0,s1
    80004c50:	ffffc097          	auipc	ra,0xffffc
    80004c54:	dae080e7          	jalr	-594(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004c58:	60e2                	ld	ra,24(sp)
    80004c5a:	6442                	ld	s0,16(sp)
    80004c5c:	64a2                	ld	s1,8(sp)
    80004c5e:	6902                	ld	s2,0(sp)
    80004c60:	6105                	addi	sp,sp,32
    80004c62:	8082                	ret
    pi->readopen = 0;
    80004c64:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c68:	21c48513          	addi	a0,s1,540
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	462080e7          	jalr	1122(ra) # 800020ce <wakeup>
    80004c74:	b7e9                	j	80004c3e <pipeclose+0x2c>
    release(&pi->lock);
    80004c76:	8526                	mv	a0,s1
    80004c78:	ffffc097          	auipc	ra,0xffffc
    80004c7c:	026080e7          	jalr	38(ra) # 80000c9e <release>
}
    80004c80:	bfe1                	j	80004c58 <pipeclose+0x46>

0000000080004c82 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c82:	7159                	addi	sp,sp,-112
    80004c84:	f486                	sd	ra,104(sp)
    80004c86:	f0a2                	sd	s0,96(sp)
    80004c88:	eca6                	sd	s1,88(sp)
    80004c8a:	e8ca                	sd	s2,80(sp)
    80004c8c:	e4ce                	sd	s3,72(sp)
    80004c8e:	e0d2                	sd	s4,64(sp)
    80004c90:	fc56                	sd	s5,56(sp)
    80004c92:	f85a                	sd	s6,48(sp)
    80004c94:	f45e                	sd	s7,40(sp)
    80004c96:	f062                	sd	s8,32(sp)
    80004c98:	ec66                	sd	s9,24(sp)
    80004c9a:	1880                	addi	s0,sp,112
    80004c9c:	84aa                	mv	s1,a0
    80004c9e:	8aae                	mv	s5,a1
    80004ca0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ca2:	ffffd097          	auipc	ra,0xffffd
    80004ca6:	d24080e7          	jalr	-732(ra) # 800019c6 <myproc>
    80004caa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	f3c080e7          	jalr	-196(ra) # 80000bea <acquire>
  while(i < n){
    80004cb6:	0d405463          	blez	s4,80004d7e <pipewrite+0xfc>
    80004cba:	8ba6                	mv	s7,s1
  int i = 0;
    80004cbc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cbe:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004cc0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004cc4:	21c48c13          	addi	s8,s1,540
    80004cc8:	a08d                	j	80004d2a <pipewrite+0xa8>
      release(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	fd2080e7          	jalr	-46(ra) # 80000c9e <release>
      return -1;
    80004cd4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004cd6:	854a                	mv	a0,s2
    80004cd8:	70a6                	ld	ra,104(sp)
    80004cda:	7406                	ld	s0,96(sp)
    80004cdc:	64e6                	ld	s1,88(sp)
    80004cde:	6946                	ld	s2,80(sp)
    80004ce0:	69a6                	ld	s3,72(sp)
    80004ce2:	6a06                	ld	s4,64(sp)
    80004ce4:	7ae2                	ld	s5,56(sp)
    80004ce6:	7b42                	ld	s6,48(sp)
    80004ce8:	7ba2                	ld	s7,40(sp)
    80004cea:	7c02                	ld	s8,32(sp)
    80004cec:	6ce2                	ld	s9,24(sp)
    80004cee:	6165                	addi	sp,sp,112
    80004cf0:	8082                	ret
      wakeup(&pi->nread);
    80004cf2:	8566                	mv	a0,s9
    80004cf4:	ffffd097          	auipc	ra,0xffffd
    80004cf8:	3da080e7          	jalr	986(ra) # 800020ce <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004cfc:	85de                	mv	a1,s7
    80004cfe:	8562                	mv	a0,s8
    80004d00:	ffffd097          	auipc	ra,0xffffd
    80004d04:	36a080e7          	jalr	874(ra) # 8000206a <sleep>
    80004d08:	a839                	j	80004d26 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d0a:	21c4a783          	lw	a5,540(s1)
    80004d0e:	0017871b          	addiw	a4,a5,1
    80004d12:	20e4ae23          	sw	a4,540(s1)
    80004d16:	1ff7f793          	andi	a5,a5,511
    80004d1a:	97a6                	add	a5,a5,s1
    80004d1c:	f9f44703          	lbu	a4,-97(s0)
    80004d20:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d24:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d26:	05495063          	bge	s2,s4,80004d66 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004d2a:	2204a783          	lw	a5,544(s1)
    80004d2e:	dfd1                	beqz	a5,80004cca <pipewrite+0x48>
    80004d30:	854e                	mv	a0,s3
    80004d32:	ffffd097          	auipc	ra,0xffffd
    80004d36:	694080e7          	jalr	1684(ra) # 800023c6 <killed>
    80004d3a:	f941                	bnez	a0,80004cca <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004d3c:	2184a783          	lw	a5,536(s1)
    80004d40:	21c4a703          	lw	a4,540(s1)
    80004d44:	2007879b          	addiw	a5,a5,512
    80004d48:	faf705e3          	beq	a4,a5,80004cf2 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d4c:	4685                	li	a3,1
    80004d4e:	01590633          	add	a2,s2,s5
    80004d52:	f9f40593          	addi	a1,s0,-97
    80004d56:	0509b503          	ld	a0,80(s3)
    80004d5a:	ffffd097          	auipc	ra,0xffffd
    80004d5e:	9b6080e7          	jalr	-1610(ra) # 80001710 <copyin>
    80004d62:	fb6514e3          	bne	a0,s6,80004d0a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d66:	21848513          	addi	a0,s1,536
    80004d6a:	ffffd097          	auipc	ra,0xffffd
    80004d6e:	364080e7          	jalr	868(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004d72:	8526                	mv	a0,s1
    80004d74:	ffffc097          	auipc	ra,0xffffc
    80004d78:	f2a080e7          	jalr	-214(ra) # 80000c9e <release>
  return i;
    80004d7c:	bfa9                	j	80004cd6 <pipewrite+0x54>
  int i = 0;
    80004d7e:	4901                	li	s2,0
    80004d80:	b7dd                	j	80004d66 <pipewrite+0xe4>

0000000080004d82 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d82:	715d                	addi	sp,sp,-80
    80004d84:	e486                	sd	ra,72(sp)
    80004d86:	e0a2                	sd	s0,64(sp)
    80004d88:	fc26                	sd	s1,56(sp)
    80004d8a:	f84a                	sd	s2,48(sp)
    80004d8c:	f44e                	sd	s3,40(sp)
    80004d8e:	f052                	sd	s4,32(sp)
    80004d90:	ec56                	sd	s5,24(sp)
    80004d92:	e85a                	sd	s6,16(sp)
    80004d94:	0880                	addi	s0,sp,80
    80004d96:	84aa                	mv	s1,a0
    80004d98:	892e                	mv	s2,a1
    80004d9a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d9c:	ffffd097          	auipc	ra,0xffffd
    80004da0:	c2a080e7          	jalr	-982(ra) # 800019c6 <myproc>
    80004da4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004da6:	8b26                	mv	s6,s1
    80004da8:	8526                	mv	a0,s1
    80004daa:	ffffc097          	auipc	ra,0xffffc
    80004dae:	e40080e7          	jalr	-448(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004db2:	2184a703          	lw	a4,536(s1)
    80004db6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dba:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004dbe:	02f71763          	bne	a4,a5,80004dec <piperead+0x6a>
    80004dc2:	2244a783          	lw	a5,548(s1)
    80004dc6:	c39d                	beqz	a5,80004dec <piperead+0x6a>
    if(killed(pr)){
    80004dc8:	8552                	mv	a0,s4
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	5fc080e7          	jalr	1532(ra) # 800023c6 <killed>
    80004dd2:	e941                	bnez	a0,80004e62 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004dd4:	85da                	mv	a1,s6
    80004dd6:	854e                	mv	a0,s3
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	292080e7          	jalr	658(ra) # 8000206a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004de0:	2184a703          	lw	a4,536(s1)
    80004de4:	21c4a783          	lw	a5,540(s1)
    80004de8:	fcf70de3          	beq	a4,a5,80004dc2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dec:	09505263          	blez	s5,80004e70 <piperead+0xee>
    80004df0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004df2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004df4:	2184a783          	lw	a5,536(s1)
    80004df8:	21c4a703          	lw	a4,540(s1)
    80004dfc:	02f70d63          	beq	a4,a5,80004e36 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e00:	0017871b          	addiw	a4,a5,1
    80004e04:	20e4ac23          	sw	a4,536(s1)
    80004e08:	1ff7f793          	andi	a5,a5,511
    80004e0c:	97a6                	add	a5,a5,s1
    80004e0e:	0187c783          	lbu	a5,24(a5)
    80004e12:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e16:	4685                	li	a3,1
    80004e18:	fbf40613          	addi	a2,s0,-65
    80004e1c:	85ca                	mv	a1,s2
    80004e1e:	050a3503          	ld	a0,80(s4)
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	862080e7          	jalr	-1950(ra) # 80001684 <copyout>
    80004e2a:	01650663          	beq	a0,s6,80004e36 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e2e:	2985                	addiw	s3,s3,1
    80004e30:	0905                	addi	s2,s2,1
    80004e32:	fd3a91e3          	bne	s5,s3,80004df4 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004e36:	21c48513          	addi	a0,s1,540
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	294080e7          	jalr	660(ra) # 800020ce <wakeup>
  release(&pi->lock);
    80004e42:	8526                	mv	a0,s1
    80004e44:	ffffc097          	auipc	ra,0xffffc
    80004e48:	e5a080e7          	jalr	-422(ra) # 80000c9e <release>
  return i;
}
    80004e4c:	854e                	mv	a0,s3
    80004e4e:	60a6                	ld	ra,72(sp)
    80004e50:	6406                	ld	s0,64(sp)
    80004e52:	74e2                	ld	s1,56(sp)
    80004e54:	7942                	ld	s2,48(sp)
    80004e56:	79a2                	ld	s3,40(sp)
    80004e58:	7a02                	ld	s4,32(sp)
    80004e5a:	6ae2                	ld	s5,24(sp)
    80004e5c:	6b42                	ld	s6,16(sp)
    80004e5e:	6161                	addi	sp,sp,80
    80004e60:	8082                	ret
      release(&pi->lock);
    80004e62:	8526                	mv	a0,s1
    80004e64:	ffffc097          	auipc	ra,0xffffc
    80004e68:	e3a080e7          	jalr	-454(ra) # 80000c9e <release>
      return -1;
    80004e6c:	59fd                	li	s3,-1
    80004e6e:	bff9                	j	80004e4c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e70:	4981                	li	s3,0
    80004e72:	b7d1                	j	80004e36 <piperead+0xb4>

0000000080004e74 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e74:	1141                	addi	sp,sp,-16
    80004e76:	e422                	sd	s0,8(sp)
    80004e78:	0800                	addi	s0,sp,16
    80004e7a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e7c:	8905                	andi	a0,a0,1
    80004e7e:	c111                	beqz	a0,80004e82 <flags2perm+0xe>
      perm = PTE_X;
    80004e80:	4521                	li	a0,8
    if(flags & 0x2)
    80004e82:	8b89                	andi	a5,a5,2
    80004e84:	c399                	beqz	a5,80004e8a <flags2perm+0x16>
      perm |= PTE_W;
    80004e86:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e8a:	6422                	ld	s0,8(sp)
    80004e8c:	0141                	addi	sp,sp,16
    80004e8e:	8082                	ret

0000000080004e90 <exec>:

int
exec(char *path, char **argv)
{
    80004e90:	df010113          	addi	sp,sp,-528
    80004e94:	20113423          	sd	ra,520(sp)
    80004e98:	20813023          	sd	s0,512(sp)
    80004e9c:	ffa6                	sd	s1,504(sp)
    80004e9e:	fbca                	sd	s2,496(sp)
    80004ea0:	f7ce                	sd	s3,488(sp)
    80004ea2:	f3d2                	sd	s4,480(sp)
    80004ea4:	efd6                	sd	s5,472(sp)
    80004ea6:	ebda                	sd	s6,464(sp)
    80004ea8:	e7de                	sd	s7,456(sp)
    80004eaa:	e3e2                	sd	s8,448(sp)
    80004eac:	ff66                	sd	s9,440(sp)
    80004eae:	fb6a                	sd	s10,432(sp)
    80004eb0:	f76e                	sd	s11,424(sp)
    80004eb2:	0c00                	addi	s0,sp,528
    80004eb4:	84aa                	mv	s1,a0
    80004eb6:	dea43c23          	sd	a0,-520(s0)
    80004eba:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ebe:	ffffd097          	auipc	ra,0xffffd
    80004ec2:	b08080e7          	jalr	-1272(ra) # 800019c6 <myproc>
    80004ec6:	892a                	mv	s2,a0

  begin_op();
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	474080e7          	jalr	1140(ra) # 8000433c <begin_op>

  if((ip = namei(path)) == 0){
    80004ed0:	8526                	mv	a0,s1
    80004ed2:	fffff097          	auipc	ra,0xfffff
    80004ed6:	24e080e7          	jalr	590(ra) # 80004120 <namei>
    80004eda:	c92d                	beqz	a0,80004f4c <exec+0xbc>
    80004edc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ede:	fffff097          	auipc	ra,0xfffff
    80004ee2:	a9c080e7          	jalr	-1380(ra) # 8000397a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ee6:	04000713          	li	a4,64
    80004eea:	4681                	li	a3,0
    80004eec:	e5040613          	addi	a2,s0,-432
    80004ef0:	4581                	li	a1,0
    80004ef2:	8526                	mv	a0,s1
    80004ef4:	fffff097          	auipc	ra,0xfffff
    80004ef8:	d3a080e7          	jalr	-710(ra) # 80003c2e <readi>
    80004efc:	04000793          	li	a5,64
    80004f00:	00f51a63          	bne	a0,a5,80004f14 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f04:	e5042703          	lw	a4,-432(s0)
    80004f08:	464c47b7          	lui	a5,0x464c4
    80004f0c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f10:	04f70463          	beq	a4,a5,80004f58 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f14:	8526                	mv	a0,s1
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	cc6080e7          	jalr	-826(ra) # 80003bdc <iunlockput>
    end_op();
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	49e080e7          	jalr	1182(ra) # 800043bc <end_op>
  }
  return -1;
    80004f26:	557d                	li	a0,-1
}
    80004f28:	20813083          	ld	ra,520(sp)
    80004f2c:	20013403          	ld	s0,512(sp)
    80004f30:	74fe                	ld	s1,504(sp)
    80004f32:	795e                	ld	s2,496(sp)
    80004f34:	79be                	ld	s3,488(sp)
    80004f36:	7a1e                	ld	s4,480(sp)
    80004f38:	6afe                	ld	s5,472(sp)
    80004f3a:	6b5e                	ld	s6,464(sp)
    80004f3c:	6bbe                	ld	s7,456(sp)
    80004f3e:	6c1e                	ld	s8,448(sp)
    80004f40:	7cfa                	ld	s9,440(sp)
    80004f42:	7d5a                	ld	s10,432(sp)
    80004f44:	7dba                	ld	s11,424(sp)
    80004f46:	21010113          	addi	sp,sp,528
    80004f4a:	8082                	ret
    end_op();
    80004f4c:	fffff097          	auipc	ra,0xfffff
    80004f50:	470080e7          	jalr	1136(ra) # 800043bc <end_op>
    return -1;
    80004f54:	557d                	li	a0,-1
    80004f56:	bfc9                	j	80004f28 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f58:	854a                	mv	a0,s2
    80004f5a:	ffffd097          	auipc	ra,0xffffd
    80004f5e:	b30080e7          	jalr	-1232(ra) # 80001a8a <proc_pagetable>
    80004f62:	8baa                	mv	s7,a0
    80004f64:	d945                	beqz	a0,80004f14 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f66:	e7042983          	lw	s3,-400(s0)
    80004f6a:	e8845783          	lhu	a5,-376(s0)
    80004f6e:	c7ad                	beqz	a5,80004fd8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f70:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f72:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f74:	6c85                	lui	s9,0x1
    80004f76:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f7a:	def43823          	sd	a5,-528(s0)
    80004f7e:	ac0d                	j	800051b0 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f80:	00003517          	auipc	a0,0x3
    80004f84:	76050513          	addi	a0,a0,1888 # 800086e0 <syscalls+0x290>
    80004f88:	ffffb097          	auipc	ra,0xffffb
    80004f8c:	5bc080e7          	jalr	1468(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f90:	8756                	mv	a4,s5
    80004f92:	012d86bb          	addw	a3,s11,s2
    80004f96:	4581                	li	a1,0
    80004f98:	8526                	mv	a0,s1
    80004f9a:	fffff097          	auipc	ra,0xfffff
    80004f9e:	c94080e7          	jalr	-876(ra) # 80003c2e <readi>
    80004fa2:	2501                	sext.w	a0,a0
    80004fa4:	1aaa9a63          	bne	s5,a0,80005158 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004fa8:	6785                	lui	a5,0x1
    80004faa:	0127893b          	addw	s2,a5,s2
    80004fae:	77fd                	lui	a5,0xfffff
    80004fb0:	01478a3b          	addw	s4,a5,s4
    80004fb4:	1f897563          	bgeu	s2,s8,8000519e <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004fb8:	02091593          	slli	a1,s2,0x20
    80004fbc:	9181                	srli	a1,a1,0x20
    80004fbe:	95ea                	add	a1,a1,s10
    80004fc0:	855e                	mv	a0,s7
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	0b6080e7          	jalr	182(ra) # 80001078 <walkaddr>
    80004fca:	862a                	mv	a2,a0
    if(pa == 0)
    80004fcc:	d955                	beqz	a0,80004f80 <exec+0xf0>
      n = PGSIZE;
    80004fce:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004fd0:	fd9a70e3          	bgeu	s4,s9,80004f90 <exec+0x100>
      n = sz - i;
    80004fd4:	8ad2                	mv	s5,s4
    80004fd6:	bf6d                	j	80004f90 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fd8:	4a01                	li	s4,0
  iunlockput(ip);
    80004fda:	8526                	mv	a0,s1
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	c00080e7          	jalr	-1024(ra) # 80003bdc <iunlockput>
  end_op();
    80004fe4:	fffff097          	auipc	ra,0xfffff
    80004fe8:	3d8080e7          	jalr	984(ra) # 800043bc <end_op>
  p = myproc();
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	9da080e7          	jalr	-1574(ra) # 800019c6 <myproc>
    80004ff4:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004ff6:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ffa:	6785                	lui	a5,0x1
    80004ffc:	17fd                	addi	a5,a5,-1
    80004ffe:	9a3e                	add	s4,s4,a5
    80005000:	757d                	lui	a0,0xfffff
    80005002:	00aa77b3          	and	a5,s4,a0
    80005006:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000500a:	4691                	li	a3,4
    8000500c:	6609                	lui	a2,0x2
    8000500e:	963e                	add	a2,a2,a5
    80005010:	85be                	mv	a1,a5
    80005012:	855e                	mv	a0,s7
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	418080e7          	jalr	1048(ra) # 8000142c <uvmalloc>
    8000501c:	8b2a                	mv	s6,a0
  ip = 0;
    8000501e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005020:	12050c63          	beqz	a0,80005158 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005024:	75f9                	lui	a1,0xffffe
    80005026:	95aa                	add	a1,a1,a0
    80005028:	855e                	mv	a0,s7
    8000502a:	ffffc097          	auipc	ra,0xffffc
    8000502e:	628080e7          	jalr	1576(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80005032:	7c7d                	lui	s8,0xfffff
    80005034:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005036:	e0043783          	ld	a5,-512(s0)
    8000503a:	6388                	ld	a0,0(a5)
    8000503c:	c535                	beqz	a0,800050a8 <exec+0x218>
    8000503e:	e9040993          	addi	s3,s0,-368
    80005042:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005046:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	e22080e7          	jalr	-478(ra) # 80000e6a <strlen>
    80005050:	2505                	addiw	a0,a0,1
    80005052:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005056:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000505a:	13896663          	bltu	s2,s8,80005186 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000505e:	e0043d83          	ld	s11,-512(s0)
    80005062:	000dba03          	ld	s4,0(s11)
    80005066:	8552                	mv	a0,s4
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	e02080e7          	jalr	-510(ra) # 80000e6a <strlen>
    80005070:	0015069b          	addiw	a3,a0,1
    80005074:	8652                	mv	a2,s4
    80005076:	85ca                	mv	a1,s2
    80005078:	855e                	mv	a0,s7
    8000507a:	ffffc097          	auipc	ra,0xffffc
    8000507e:	60a080e7          	jalr	1546(ra) # 80001684 <copyout>
    80005082:	10054663          	bltz	a0,8000518e <exec+0x2fe>
    ustack[argc] = sp;
    80005086:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000508a:	0485                	addi	s1,s1,1
    8000508c:	008d8793          	addi	a5,s11,8
    80005090:	e0f43023          	sd	a5,-512(s0)
    80005094:	008db503          	ld	a0,8(s11)
    80005098:	c911                	beqz	a0,800050ac <exec+0x21c>
    if(argc >= MAXARG)
    8000509a:	09a1                	addi	s3,s3,8
    8000509c:	fb3c96e3          	bne	s9,s3,80005048 <exec+0x1b8>
  sz = sz1;
    800050a0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a4:	4481                	li	s1,0
    800050a6:	a84d                	j	80005158 <exec+0x2c8>
  sp = sz;
    800050a8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800050aa:	4481                	li	s1,0
  ustack[argc] = 0;
    800050ac:	00349793          	slli	a5,s1,0x3
    800050b0:	f9040713          	addi	a4,s0,-112
    800050b4:	97ba                	add	a5,a5,a4
    800050b6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800050ba:	00148693          	addi	a3,s1,1
    800050be:	068e                	slli	a3,a3,0x3
    800050c0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800050c4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800050c8:	01897663          	bgeu	s2,s8,800050d4 <exec+0x244>
  sz = sz1;
    800050cc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d0:	4481                	li	s1,0
    800050d2:	a059                	j	80005158 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800050d4:	e9040613          	addi	a2,s0,-368
    800050d8:	85ca                	mv	a1,s2
    800050da:	855e                	mv	a0,s7
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	5a8080e7          	jalr	1448(ra) # 80001684 <copyout>
    800050e4:	0a054963          	bltz	a0,80005196 <exec+0x306>
  p->trapframe->a1 = sp;
    800050e8:	058ab783          	ld	a5,88(s5)
    800050ec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800050f0:	df843783          	ld	a5,-520(s0)
    800050f4:	0007c703          	lbu	a4,0(a5)
    800050f8:	cf11                	beqz	a4,80005114 <exec+0x284>
    800050fa:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050fc:	02f00693          	li	a3,47
    80005100:	a039                	j	8000510e <exec+0x27e>
      last = s+1;
    80005102:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005106:	0785                	addi	a5,a5,1
    80005108:	fff7c703          	lbu	a4,-1(a5)
    8000510c:	c701                	beqz	a4,80005114 <exec+0x284>
    if(*s == '/')
    8000510e:	fed71ce3          	bne	a4,a3,80005106 <exec+0x276>
    80005112:	bfc5                	j	80005102 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005114:	4641                	li	a2,16
    80005116:	df843583          	ld	a1,-520(s0)
    8000511a:	158a8513          	addi	a0,s5,344
    8000511e:	ffffc097          	auipc	ra,0xffffc
    80005122:	d1a080e7          	jalr	-742(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005126:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000512a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000512e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005132:	058ab783          	ld	a5,88(s5)
    80005136:	e6843703          	ld	a4,-408(s0)
    8000513a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000513c:	058ab783          	ld	a5,88(s5)
    80005140:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005144:	85ea                	mv	a1,s10
    80005146:	ffffd097          	auipc	ra,0xffffd
    8000514a:	9e0080e7          	jalr	-1568(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000514e:	0004851b          	sext.w	a0,s1
    80005152:	bbd9                	j	80004f28 <exec+0x98>
    80005154:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005158:	e0843583          	ld	a1,-504(s0)
    8000515c:	855e                	mv	a0,s7
    8000515e:	ffffd097          	auipc	ra,0xffffd
    80005162:	9c8080e7          	jalr	-1592(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005166:	da0497e3          	bnez	s1,80004f14 <exec+0x84>
  return -1;
    8000516a:	557d                	li	a0,-1
    8000516c:	bb75                	j	80004f28 <exec+0x98>
    8000516e:	e1443423          	sd	s4,-504(s0)
    80005172:	b7dd                	j	80005158 <exec+0x2c8>
    80005174:	e1443423          	sd	s4,-504(s0)
    80005178:	b7c5                	j	80005158 <exec+0x2c8>
    8000517a:	e1443423          	sd	s4,-504(s0)
    8000517e:	bfe9                	j	80005158 <exec+0x2c8>
    80005180:	e1443423          	sd	s4,-504(s0)
    80005184:	bfd1                	j	80005158 <exec+0x2c8>
  sz = sz1;
    80005186:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000518a:	4481                	li	s1,0
    8000518c:	b7f1                	j	80005158 <exec+0x2c8>
  sz = sz1;
    8000518e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005192:	4481                	li	s1,0
    80005194:	b7d1                	j	80005158 <exec+0x2c8>
  sz = sz1;
    80005196:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000519a:	4481                	li	s1,0
    8000519c:	bf75                	j	80005158 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000519e:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051a2:	2b05                	addiw	s6,s6,1
    800051a4:	0389899b          	addiw	s3,s3,56
    800051a8:	e8845783          	lhu	a5,-376(s0)
    800051ac:	e2fb57e3          	bge	s6,a5,80004fda <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800051b0:	2981                	sext.w	s3,s3
    800051b2:	03800713          	li	a4,56
    800051b6:	86ce                	mv	a3,s3
    800051b8:	e1840613          	addi	a2,s0,-488
    800051bc:	4581                	li	a1,0
    800051be:	8526                	mv	a0,s1
    800051c0:	fffff097          	auipc	ra,0xfffff
    800051c4:	a6e080e7          	jalr	-1426(ra) # 80003c2e <readi>
    800051c8:	03800793          	li	a5,56
    800051cc:	f8f514e3          	bne	a0,a5,80005154 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800051d0:	e1842783          	lw	a5,-488(s0)
    800051d4:	4705                	li	a4,1
    800051d6:	fce796e3          	bne	a5,a4,800051a2 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800051da:	e4043903          	ld	s2,-448(s0)
    800051de:	e3843783          	ld	a5,-456(s0)
    800051e2:	f8f966e3          	bltu	s2,a5,8000516e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800051e6:	e2843783          	ld	a5,-472(s0)
    800051ea:	993e                	add	s2,s2,a5
    800051ec:	f8f964e3          	bltu	s2,a5,80005174 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800051f0:	df043703          	ld	a4,-528(s0)
    800051f4:	8ff9                	and	a5,a5,a4
    800051f6:	f3d1                	bnez	a5,8000517a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051f8:	e1c42503          	lw	a0,-484(s0)
    800051fc:	00000097          	auipc	ra,0x0
    80005200:	c78080e7          	jalr	-904(ra) # 80004e74 <flags2perm>
    80005204:	86aa                	mv	a3,a0
    80005206:	864a                	mv	a2,s2
    80005208:	85d2                	mv	a1,s4
    8000520a:	855e                	mv	a0,s7
    8000520c:	ffffc097          	auipc	ra,0xffffc
    80005210:	220080e7          	jalr	544(ra) # 8000142c <uvmalloc>
    80005214:	e0a43423          	sd	a0,-504(s0)
    80005218:	d525                	beqz	a0,80005180 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000521a:	e2843d03          	ld	s10,-472(s0)
    8000521e:	e2042d83          	lw	s11,-480(s0)
    80005222:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005226:	f60c0ce3          	beqz	s8,8000519e <exec+0x30e>
    8000522a:	8a62                	mv	s4,s8
    8000522c:	4901                	li	s2,0
    8000522e:	b369                	j	80004fb8 <exec+0x128>

0000000080005230 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005230:	7179                	addi	sp,sp,-48
    80005232:	f406                	sd	ra,40(sp)
    80005234:	f022                	sd	s0,32(sp)
    80005236:	ec26                	sd	s1,24(sp)
    80005238:	e84a                	sd	s2,16(sp)
    8000523a:	1800                	addi	s0,sp,48
    8000523c:	892e                	mv	s2,a1
    8000523e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005240:	fdc40593          	addi	a1,s0,-36
    80005244:	ffffe097          	auipc	ra,0xffffe
    80005248:	b52080e7          	jalr	-1198(ra) # 80002d96 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000524c:	fdc42703          	lw	a4,-36(s0)
    80005250:	47bd                	li	a5,15
    80005252:	02e7eb63          	bltu	a5,a4,80005288 <argfd+0x58>
    80005256:	ffffc097          	auipc	ra,0xffffc
    8000525a:	770080e7          	jalr	1904(ra) # 800019c6 <myproc>
    8000525e:	fdc42703          	lw	a4,-36(s0)
    80005262:	01a70793          	addi	a5,a4,26
    80005266:	078e                	slli	a5,a5,0x3
    80005268:	953e                	add	a0,a0,a5
    8000526a:	611c                	ld	a5,0(a0)
    8000526c:	c385                	beqz	a5,8000528c <argfd+0x5c>
    return -1;
  if(pfd)
    8000526e:	00090463          	beqz	s2,80005276 <argfd+0x46>
    *pfd = fd;
    80005272:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005276:	4501                	li	a0,0
  if(pf)
    80005278:	c091                	beqz	s1,8000527c <argfd+0x4c>
    *pf = f;
    8000527a:	e09c                	sd	a5,0(s1)
}
    8000527c:	70a2                	ld	ra,40(sp)
    8000527e:	7402                	ld	s0,32(sp)
    80005280:	64e2                	ld	s1,24(sp)
    80005282:	6942                	ld	s2,16(sp)
    80005284:	6145                	addi	sp,sp,48
    80005286:	8082                	ret
    return -1;
    80005288:	557d                	li	a0,-1
    8000528a:	bfcd                	j	8000527c <argfd+0x4c>
    8000528c:	557d                	li	a0,-1
    8000528e:	b7fd                	j	8000527c <argfd+0x4c>

0000000080005290 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005290:	1101                	addi	sp,sp,-32
    80005292:	ec06                	sd	ra,24(sp)
    80005294:	e822                	sd	s0,16(sp)
    80005296:	e426                	sd	s1,8(sp)
    80005298:	1000                	addi	s0,sp,32
    8000529a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	72a080e7          	jalr	1834(ra) # 800019c6 <myproc>
    800052a4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052a6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffdd380>
    800052aa:	4501                	li	a0,0
    800052ac:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052ae:	6398                	ld	a4,0(a5)
    800052b0:	cb19                	beqz	a4,800052c6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052b2:	2505                	addiw	a0,a0,1
    800052b4:	07a1                	addi	a5,a5,8
    800052b6:	fed51ce3          	bne	a0,a3,800052ae <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052ba:	557d                	li	a0,-1
}
    800052bc:	60e2                	ld	ra,24(sp)
    800052be:	6442                	ld	s0,16(sp)
    800052c0:	64a2                	ld	s1,8(sp)
    800052c2:	6105                	addi	sp,sp,32
    800052c4:	8082                	ret
      p->ofile[fd] = f;
    800052c6:	01a50793          	addi	a5,a0,26
    800052ca:	078e                	slli	a5,a5,0x3
    800052cc:	963e                	add	a2,a2,a5
    800052ce:	e204                	sd	s1,0(a2)
      return fd;
    800052d0:	b7f5                	j	800052bc <fdalloc+0x2c>

00000000800052d2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800052d2:	715d                	addi	sp,sp,-80
    800052d4:	e486                	sd	ra,72(sp)
    800052d6:	e0a2                	sd	s0,64(sp)
    800052d8:	fc26                	sd	s1,56(sp)
    800052da:	f84a                	sd	s2,48(sp)
    800052dc:	f44e                	sd	s3,40(sp)
    800052de:	f052                	sd	s4,32(sp)
    800052e0:	ec56                	sd	s5,24(sp)
    800052e2:	e85a                	sd	s6,16(sp)
    800052e4:	0880                	addi	s0,sp,80
    800052e6:	8b2e                	mv	s6,a1
    800052e8:	89b2                	mv	s3,a2
    800052ea:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800052ec:	fb040593          	addi	a1,s0,-80
    800052f0:	fffff097          	auipc	ra,0xfffff
    800052f4:	e4e080e7          	jalr	-434(ra) # 8000413e <nameiparent>
    800052f8:	84aa                	mv	s1,a0
    800052fa:	16050063          	beqz	a0,8000545a <create+0x188>
    return 0;

  ilock(dp);
    800052fe:	ffffe097          	auipc	ra,0xffffe
    80005302:	67c080e7          	jalr	1660(ra) # 8000397a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005306:	4601                	li	a2,0
    80005308:	fb040593          	addi	a1,s0,-80
    8000530c:	8526                	mv	a0,s1
    8000530e:	fffff097          	auipc	ra,0xfffff
    80005312:	b50080e7          	jalr	-1200(ra) # 80003e5e <dirlookup>
    80005316:	8aaa                	mv	s5,a0
    80005318:	c931                	beqz	a0,8000536c <create+0x9a>
    iunlockput(dp);
    8000531a:	8526                	mv	a0,s1
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	8c0080e7          	jalr	-1856(ra) # 80003bdc <iunlockput>
    ilock(ip);
    80005324:	8556                	mv	a0,s5
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	654080e7          	jalr	1620(ra) # 8000397a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000532e:	000b059b          	sext.w	a1,s6
    80005332:	4789                	li	a5,2
    80005334:	02f59563          	bne	a1,a5,8000535e <create+0x8c>
    80005338:	044ad783          	lhu	a5,68(s5)
    8000533c:	37f9                	addiw	a5,a5,-2
    8000533e:	17c2                	slli	a5,a5,0x30
    80005340:	93c1                	srli	a5,a5,0x30
    80005342:	4705                	li	a4,1
    80005344:	00f76d63          	bltu	a4,a5,8000535e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005348:	8556                	mv	a0,s5
    8000534a:	60a6                	ld	ra,72(sp)
    8000534c:	6406                	ld	s0,64(sp)
    8000534e:	74e2                	ld	s1,56(sp)
    80005350:	7942                	ld	s2,48(sp)
    80005352:	79a2                	ld	s3,40(sp)
    80005354:	7a02                	ld	s4,32(sp)
    80005356:	6ae2                	ld	s5,24(sp)
    80005358:	6b42                	ld	s6,16(sp)
    8000535a:	6161                	addi	sp,sp,80
    8000535c:	8082                	ret
    iunlockput(ip);
    8000535e:	8556                	mv	a0,s5
    80005360:	fffff097          	auipc	ra,0xfffff
    80005364:	87c080e7          	jalr	-1924(ra) # 80003bdc <iunlockput>
    return 0;
    80005368:	4a81                	li	s5,0
    8000536a:	bff9                	j	80005348 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000536c:	85da                	mv	a1,s6
    8000536e:	4088                	lw	a0,0(s1)
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	46e080e7          	jalr	1134(ra) # 800037de <ialloc>
    80005378:	8a2a                	mv	s4,a0
    8000537a:	c921                	beqz	a0,800053ca <create+0xf8>
  ilock(ip);
    8000537c:	ffffe097          	auipc	ra,0xffffe
    80005380:	5fe080e7          	jalr	1534(ra) # 8000397a <ilock>
  ip->major = major;
    80005384:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005388:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000538c:	4785                	li	a5,1
    8000538e:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005392:	8552                	mv	a0,s4
    80005394:	ffffe097          	auipc	ra,0xffffe
    80005398:	51c080e7          	jalr	1308(ra) # 800038b0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000539c:	000b059b          	sext.w	a1,s6
    800053a0:	4785                	li	a5,1
    800053a2:	02f58b63          	beq	a1,a5,800053d8 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800053a6:	004a2603          	lw	a2,4(s4)
    800053aa:	fb040593          	addi	a1,s0,-80
    800053ae:	8526                	mv	a0,s1
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	cbe080e7          	jalr	-834(ra) # 8000406e <dirlink>
    800053b8:	06054f63          	bltz	a0,80005436 <create+0x164>
  iunlockput(dp);
    800053bc:	8526                	mv	a0,s1
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	81e080e7          	jalr	-2018(ra) # 80003bdc <iunlockput>
  return ip;
    800053c6:	8ad2                	mv	s5,s4
    800053c8:	b741                	j	80005348 <create+0x76>
    iunlockput(dp);
    800053ca:	8526                	mv	a0,s1
    800053cc:	fffff097          	auipc	ra,0xfffff
    800053d0:	810080e7          	jalr	-2032(ra) # 80003bdc <iunlockput>
    return 0;
    800053d4:	8ad2                	mv	s5,s4
    800053d6:	bf8d                	j	80005348 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800053d8:	004a2603          	lw	a2,4(s4)
    800053dc:	00003597          	auipc	a1,0x3
    800053e0:	32458593          	addi	a1,a1,804 # 80008700 <syscalls+0x2b0>
    800053e4:	8552                	mv	a0,s4
    800053e6:	fffff097          	auipc	ra,0xfffff
    800053ea:	c88080e7          	jalr	-888(ra) # 8000406e <dirlink>
    800053ee:	04054463          	bltz	a0,80005436 <create+0x164>
    800053f2:	40d0                	lw	a2,4(s1)
    800053f4:	00003597          	auipc	a1,0x3
    800053f8:	31458593          	addi	a1,a1,788 # 80008708 <syscalls+0x2b8>
    800053fc:	8552                	mv	a0,s4
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	c70080e7          	jalr	-912(ra) # 8000406e <dirlink>
    80005406:	02054863          	bltz	a0,80005436 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000540a:	004a2603          	lw	a2,4(s4)
    8000540e:	fb040593          	addi	a1,s0,-80
    80005412:	8526                	mv	a0,s1
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	c5a080e7          	jalr	-934(ra) # 8000406e <dirlink>
    8000541c:	00054d63          	bltz	a0,80005436 <create+0x164>
    dp->nlink++;  // for ".."
    80005420:	04a4d783          	lhu	a5,74(s1)
    80005424:	2785                	addiw	a5,a5,1
    80005426:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000542a:	8526                	mv	a0,s1
    8000542c:	ffffe097          	auipc	ra,0xffffe
    80005430:	484080e7          	jalr	1156(ra) # 800038b0 <iupdate>
    80005434:	b761                	j	800053bc <create+0xea>
  ip->nlink = 0;
    80005436:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000543a:	8552                	mv	a0,s4
    8000543c:	ffffe097          	auipc	ra,0xffffe
    80005440:	474080e7          	jalr	1140(ra) # 800038b0 <iupdate>
  iunlockput(ip);
    80005444:	8552                	mv	a0,s4
    80005446:	ffffe097          	auipc	ra,0xffffe
    8000544a:	796080e7          	jalr	1942(ra) # 80003bdc <iunlockput>
  iunlockput(dp);
    8000544e:	8526                	mv	a0,s1
    80005450:	ffffe097          	auipc	ra,0xffffe
    80005454:	78c080e7          	jalr	1932(ra) # 80003bdc <iunlockput>
  return 0;
    80005458:	bdc5                	j	80005348 <create+0x76>
    return 0;
    8000545a:	8aaa                	mv	s5,a0
    8000545c:	b5f5                	j	80005348 <create+0x76>

000000008000545e <sys_dup>:
{
    8000545e:	7179                	addi	sp,sp,-48
    80005460:	f406                	sd	ra,40(sp)
    80005462:	f022                	sd	s0,32(sp)
    80005464:	ec26                	sd	s1,24(sp)
    80005466:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005468:	fd840613          	addi	a2,s0,-40
    8000546c:	4581                	li	a1,0
    8000546e:	4501                	li	a0,0
    80005470:	00000097          	auipc	ra,0x0
    80005474:	dc0080e7          	jalr	-576(ra) # 80005230 <argfd>
    return -1;
    80005478:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000547a:	02054363          	bltz	a0,800054a0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000547e:	fd843503          	ld	a0,-40(s0)
    80005482:	00000097          	auipc	ra,0x0
    80005486:	e0e080e7          	jalr	-498(ra) # 80005290 <fdalloc>
    8000548a:	84aa                	mv	s1,a0
    return -1;
    8000548c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000548e:	00054963          	bltz	a0,800054a0 <sys_dup+0x42>
  filedup(f);
    80005492:	fd843503          	ld	a0,-40(s0)
    80005496:	fffff097          	auipc	ra,0xfffff
    8000549a:	320080e7          	jalr	800(ra) # 800047b6 <filedup>
  return fd;
    8000549e:	87a6                	mv	a5,s1
}
    800054a0:	853e                	mv	a0,a5
    800054a2:	70a2                	ld	ra,40(sp)
    800054a4:	7402                	ld	s0,32(sp)
    800054a6:	64e2                	ld	s1,24(sp)
    800054a8:	6145                	addi	sp,sp,48
    800054aa:	8082                	ret

00000000800054ac <sys_read>:
{
    800054ac:	7179                	addi	sp,sp,-48
    800054ae:	f406                	sd	ra,40(sp)
    800054b0:	f022                	sd	s0,32(sp)
    800054b2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054b4:	fd840593          	addi	a1,s0,-40
    800054b8:	4505                	li	a0,1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	8fc080e7          	jalr	-1796(ra) # 80002db6 <argaddr>
  argint(2, &n);
    800054c2:	fe440593          	addi	a1,s0,-28
    800054c6:	4509                	li	a0,2
    800054c8:	ffffe097          	auipc	ra,0xffffe
    800054cc:	8ce080e7          	jalr	-1842(ra) # 80002d96 <argint>
  if(argfd(0, 0, &f) < 0)
    800054d0:	fe840613          	addi	a2,s0,-24
    800054d4:	4581                	li	a1,0
    800054d6:	4501                	li	a0,0
    800054d8:	00000097          	auipc	ra,0x0
    800054dc:	d58080e7          	jalr	-680(ra) # 80005230 <argfd>
    800054e0:	87aa                	mv	a5,a0
    return -1;
    800054e2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054e4:	0007cc63          	bltz	a5,800054fc <sys_read+0x50>
  return fileread(f, p, n);
    800054e8:	fe442603          	lw	a2,-28(s0)
    800054ec:	fd843583          	ld	a1,-40(s0)
    800054f0:	fe843503          	ld	a0,-24(s0)
    800054f4:	fffff097          	auipc	ra,0xfffff
    800054f8:	44e080e7          	jalr	1102(ra) # 80004942 <fileread>
}
    800054fc:	70a2                	ld	ra,40(sp)
    800054fe:	7402                	ld	s0,32(sp)
    80005500:	6145                	addi	sp,sp,48
    80005502:	8082                	ret

0000000080005504 <sys_write>:
{
    80005504:	7179                	addi	sp,sp,-48
    80005506:	f406                	sd	ra,40(sp)
    80005508:	f022                	sd	s0,32(sp)
    8000550a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000550c:	fd840593          	addi	a1,s0,-40
    80005510:	4505                	li	a0,1
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	8a4080e7          	jalr	-1884(ra) # 80002db6 <argaddr>
  argint(2, &n);
    8000551a:	fe440593          	addi	a1,s0,-28
    8000551e:	4509                	li	a0,2
    80005520:	ffffe097          	auipc	ra,0xffffe
    80005524:	876080e7          	jalr	-1930(ra) # 80002d96 <argint>
  if(argfd(0, 0, &f) < 0)
    80005528:	fe840613          	addi	a2,s0,-24
    8000552c:	4581                	li	a1,0
    8000552e:	4501                	li	a0,0
    80005530:	00000097          	auipc	ra,0x0
    80005534:	d00080e7          	jalr	-768(ra) # 80005230 <argfd>
    80005538:	87aa                	mv	a5,a0
    return -1;
    8000553a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000553c:	0007cc63          	bltz	a5,80005554 <sys_write+0x50>
  return filewrite(f, p, n);
    80005540:	fe442603          	lw	a2,-28(s0)
    80005544:	fd843583          	ld	a1,-40(s0)
    80005548:	fe843503          	ld	a0,-24(s0)
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	4b8080e7          	jalr	1208(ra) # 80004a04 <filewrite>
}
    80005554:	70a2                	ld	ra,40(sp)
    80005556:	7402                	ld	s0,32(sp)
    80005558:	6145                	addi	sp,sp,48
    8000555a:	8082                	ret

000000008000555c <sys_close>:
{
    8000555c:	1101                	addi	sp,sp,-32
    8000555e:	ec06                	sd	ra,24(sp)
    80005560:	e822                	sd	s0,16(sp)
    80005562:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005564:	fe040613          	addi	a2,s0,-32
    80005568:	fec40593          	addi	a1,s0,-20
    8000556c:	4501                	li	a0,0
    8000556e:	00000097          	auipc	ra,0x0
    80005572:	cc2080e7          	jalr	-830(ra) # 80005230 <argfd>
    return -1;
    80005576:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005578:	02054463          	bltz	a0,800055a0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000557c:	ffffc097          	auipc	ra,0xffffc
    80005580:	44a080e7          	jalr	1098(ra) # 800019c6 <myproc>
    80005584:	fec42783          	lw	a5,-20(s0)
    80005588:	07e9                	addi	a5,a5,26
    8000558a:	078e                	slli	a5,a5,0x3
    8000558c:	97aa                	add	a5,a5,a0
    8000558e:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005592:	fe043503          	ld	a0,-32(s0)
    80005596:	fffff097          	auipc	ra,0xfffff
    8000559a:	272080e7          	jalr	626(ra) # 80004808 <fileclose>
  return 0;
    8000559e:	4781                	li	a5,0
}
    800055a0:	853e                	mv	a0,a5
    800055a2:	60e2                	ld	ra,24(sp)
    800055a4:	6442                	ld	s0,16(sp)
    800055a6:	6105                	addi	sp,sp,32
    800055a8:	8082                	ret

00000000800055aa <sys_fstat>:
{
    800055aa:	1101                	addi	sp,sp,-32
    800055ac:	ec06                	sd	ra,24(sp)
    800055ae:	e822                	sd	s0,16(sp)
    800055b0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800055b2:	fe040593          	addi	a1,s0,-32
    800055b6:	4505                	li	a0,1
    800055b8:	ffffd097          	auipc	ra,0xffffd
    800055bc:	7fe080e7          	jalr	2046(ra) # 80002db6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800055c0:	fe840613          	addi	a2,s0,-24
    800055c4:	4581                	li	a1,0
    800055c6:	4501                	li	a0,0
    800055c8:	00000097          	auipc	ra,0x0
    800055cc:	c68080e7          	jalr	-920(ra) # 80005230 <argfd>
    800055d0:	87aa                	mv	a5,a0
    return -1;
    800055d2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055d4:	0007ca63          	bltz	a5,800055e8 <sys_fstat+0x3e>
  return filestat(f, st);
    800055d8:	fe043583          	ld	a1,-32(s0)
    800055dc:	fe843503          	ld	a0,-24(s0)
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	2f0080e7          	jalr	752(ra) # 800048d0 <filestat>
}
    800055e8:	60e2                	ld	ra,24(sp)
    800055ea:	6442                	ld	s0,16(sp)
    800055ec:	6105                	addi	sp,sp,32
    800055ee:	8082                	ret

00000000800055f0 <sys_link>:
{
    800055f0:	7169                	addi	sp,sp,-304
    800055f2:	f606                	sd	ra,296(sp)
    800055f4:	f222                	sd	s0,288(sp)
    800055f6:	ee26                	sd	s1,280(sp)
    800055f8:	ea4a                	sd	s2,272(sp)
    800055fa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055fc:	08000613          	li	a2,128
    80005600:	ed040593          	addi	a1,s0,-304
    80005604:	4501                	li	a0,0
    80005606:	ffffd097          	auipc	ra,0xffffd
    8000560a:	7d0080e7          	jalr	2000(ra) # 80002dd6 <argstr>
    return -1;
    8000560e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005610:	10054e63          	bltz	a0,8000572c <sys_link+0x13c>
    80005614:	08000613          	li	a2,128
    80005618:	f5040593          	addi	a1,s0,-176
    8000561c:	4505                	li	a0,1
    8000561e:	ffffd097          	auipc	ra,0xffffd
    80005622:	7b8080e7          	jalr	1976(ra) # 80002dd6 <argstr>
    return -1;
    80005626:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005628:	10054263          	bltz	a0,8000572c <sys_link+0x13c>
  begin_op();
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	d10080e7          	jalr	-752(ra) # 8000433c <begin_op>
  if((ip = namei(old)) == 0){
    80005634:	ed040513          	addi	a0,s0,-304
    80005638:	fffff097          	auipc	ra,0xfffff
    8000563c:	ae8080e7          	jalr	-1304(ra) # 80004120 <namei>
    80005640:	84aa                	mv	s1,a0
    80005642:	c551                	beqz	a0,800056ce <sys_link+0xde>
  ilock(ip);
    80005644:	ffffe097          	auipc	ra,0xffffe
    80005648:	336080e7          	jalr	822(ra) # 8000397a <ilock>
  if(ip->type == T_DIR){
    8000564c:	04449703          	lh	a4,68(s1)
    80005650:	4785                	li	a5,1
    80005652:	08f70463          	beq	a4,a5,800056da <sys_link+0xea>
  ip->nlink++;
    80005656:	04a4d783          	lhu	a5,74(s1)
    8000565a:	2785                	addiw	a5,a5,1
    8000565c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005660:	8526                	mv	a0,s1
    80005662:	ffffe097          	auipc	ra,0xffffe
    80005666:	24e080e7          	jalr	590(ra) # 800038b0 <iupdate>
  iunlock(ip);
    8000566a:	8526                	mv	a0,s1
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	3d0080e7          	jalr	976(ra) # 80003a3c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005674:	fd040593          	addi	a1,s0,-48
    80005678:	f5040513          	addi	a0,s0,-176
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	ac2080e7          	jalr	-1342(ra) # 8000413e <nameiparent>
    80005684:	892a                	mv	s2,a0
    80005686:	c935                	beqz	a0,800056fa <sys_link+0x10a>
  ilock(dp);
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	2f2080e7          	jalr	754(ra) # 8000397a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005690:	00092703          	lw	a4,0(s2)
    80005694:	409c                	lw	a5,0(s1)
    80005696:	04f71d63          	bne	a4,a5,800056f0 <sys_link+0x100>
    8000569a:	40d0                	lw	a2,4(s1)
    8000569c:	fd040593          	addi	a1,s0,-48
    800056a0:	854a                	mv	a0,s2
    800056a2:	fffff097          	auipc	ra,0xfffff
    800056a6:	9cc080e7          	jalr	-1588(ra) # 8000406e <dirlink>
    800056aa:	04054363          	bltz	a0,800056f0 <sys_link+0x100>
  iunlockput(dp);
    800056ae:	854a                	mv	a0,s2
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	52c080e7          	jalr	1324(ra) # 80003bdc <iunlockput>
  iput(ip);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	47a080e7          	jalr	1146(ra) # 80003b34 <iput>
  end_op();
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	cfa080e7          	jalr	-774(ra) # 800043bc <end_op>
  return 0;
    800056ca:	4781                	li	a5,0
    800056cc:	a085                	j	8000572c <sys_link+0x13c>
    end_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	cee080e7          	jalr	-786(ra) # 800043bc <end_op>
    return -1;
    800056d6:	57fd                	li	a5,-1
    800056d8:	a891                	j	8000572c <sys_link+0x13c>
    iunlockput(ip);
    800056da:	8526                	mv	a0,s1
    800056dc:	ffffe097          	auipc	ra,0xffffe
    800056e0:	500080e7          	jalr	1280(ra) # 80003bdc <iunlockput>
    end_op();
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	cd8080e7          	jalr	-808(ra) # 800043bc <end_op>
    return -1;
    800056ec:	57fd                	li	a5,-1
    800056ee:	a83d                	j	8000572c <sys_link+0x13c>
    iunlockput(dp);
    800056f0:	854a                	mv	a0,s2
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	4ea080e7          	jalr	1258(ra) # 80003bdc <iunlockput>
  ilock(ip);
    800056fa:	8526                	mv	a0,s1
    800056fc:	ffffe097          	auipc	ra,0xffffe
    80005700:	27e080e7          	jalr	638(ra) # 8000397a <ilock>
  ip->nlink--;
    80005704:	04a4d783          	lhu	a5,74(s1)
    80005708:	37fd                	addiw	a5,a5,-1
    8000570a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	1a0080e7          	jalr	416(ra) # 800038b0 <iupdate>
  iunlockput(ip);
    80005718:	8526                	mv	a0,s1
    8000571a:	ffffe097          	auipc	ra,0xffffe
    8000571e:	4c2080e7          	jalr	1218(ra) # 80003bdc <iunlockput>
  end_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	c9a080e7          	jalr	-870(ra) # 800043bc <end_op>
  return -1;
    8000572a:	57fd                	li	a5,-1
}
    8000572c:	853e                	mv	a0,a5
    8000572e:	70b2                	ld	ra,296(sp)
    80005730:	7412                	ld	s0,288(sp)
    80005732:	64f2                	ld	s1,280(sp)
    80005734:	6952                	ld	s2,272(sp)
    80005736:	6155                	addi	sp,sp,304
    80005738:	8082                	ret

000000008000573a <sys_unlink>:
{
    8000573a:	7151                	addi	sp,sp,-240
    8000573c:	f586                	sd	ra,232(sp)
    8000573e:	f1a2                	sd	s0,224(sp)
    80005740:	eda6                	sd	s1,216(sp)
    80005742:	e9ca                	sd	s2,208(sp)
    80005744:	e5ce                	sd	s3,200(sp)
    80005746:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005748:	08000613          	li	a2,128
    8000574c:	f3040593          	addi	a1,s0,-208
    80005750:	4501                	li	a0,0
    80005752:	ffffd097          	auipc	ra,0xffffd
    80005756:	684080e7          	jalr	1668(ra) # 80002dd6 <argstr>
    8000575a:	18054163          	bltz	a0,800058dc <sys_unlink+0x1a2>
  begin_op();
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	bde080e7          	jalr	-1058(ra) # 8000433c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005766:	fb040593          	addi	a1,s0,-80
    8000576a:	f3040513          	addi	a0,s0,-208
    8000576e:	fffff097          	auipc	ra,0xfffff
    80005772:	9d0080e7          	jalr	-1584(ra) # 8000413e <nameiparent>
    80005776:	84aa                	mv	s1,a0
    80005778:	c979                	beqz	a0,8000584e <sys_unlink+0x114>
  ilock(dp);
    8000577a:	ffffe097          	auipc	ra,0xffffe
    8000577e:	200080e7          	jalr	512(ra) # 8000397a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005782:	00003597          	auipc	a1,0x3
    80005786:	f7e58593          	addi	a1,a1,-130 # 80008700 <syscalls+0x2b0>
    8000578a:	fb040513          	addi	a0,s0,-80
    8000578e:	ffffe097          	auipc	ra,0xffffe
    80005792:	6b6080e7          	jalr	1718(ra) # 80003e44 <namecmp>
    80005796:	14050a63          	beqz	a0,800058ea <sys_unlink+0x1b0>
    8000579a:	00003597          	auipc	a1,0x3
    8000579e:	f6e58593          	addi	a1,a1,-146 # 80008708 <syscalls+0x2b8>
    800057a2:	fb040513          	addi	a0,s0,-80
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	69e080e7          	jalr	1694(ra) # 80003e44 <namecmp>
    800057ae:	12050e63          	beqz	a0,800058ea <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057b2:	f2c40613          	addi	a2,s0,-212
    800057b6:	fb040593          	addi	a1,s0,-80
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	6a2080e7          	jalr	1698(ra) # 80003e5e <dirlookup>
    800057c4:	892a                	mv	s2,a0
    800057c6:	12050263          	beqz	a0,800058ea <sys_unlink+0x1b0>
  ilock(ip);
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	1b0080e7          	jalr	432(ra) # 8000397a <ilock>
  if(ip->nlink < 1)
    800057d2:	04a91783          	lh	a5,74(s2)
    800057d6:	08f05263          	blez	a5,8000585a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800057da:	04491703          	lh	a4,68(s2)
    800057de:	4785                	li	a5,1
    800057e0:	08f70563          	beq	a4,a5,8000586a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800057e4:	4641                	li	a2,16
    800057e6:	4581                	li	a1,0
    800057e8:	fc040513          	addi	a0,s0,-64
    800057ec:	ffffb097          	auipc	ra,0xffffb
    800057f0:	4fa080e7          	jalr	1274(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057f4:	4741                	li	a4,16
    800057f6:	f2c42683          	lw	a3,-212(s0)
    800057fa:	fc040613          	addi	a2,s0,-64
    800057fe:	4581                	li	a1,0
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	524080e7          	jalr	1316(ra) # 80003d26 <writei>
    8000580a:	47c1                	li	a5,16
    8000580c:	0af51563          	bne	a0,a5,800058b6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005810:	04491703          	lh	a4,68(s2)
    80005814:	4785                	li	a5,1
    80005816:	0af70863          	beq	a4,a5,800058c6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000581a:	8526                	mv	a0,s1
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	3c0080e7          	jalr	960(ra) # 80003bdc <iunlockput>
  ip->nlink--;
    80005824:	04a95783          	lhu	a5,74(s2)
    80005828:	37fd                	addiw	a5,a5,-1
    8000582a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000582e:	854a                	mv	a0,s2
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	080080e7          	jalr	128(ra) # 800038b0 <iupdate>
  iunlockput(ip);
    80005838:	854a                	mv	a0,s2
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	3a2080e7          	jalr	930(ra) # 80003bdc <iunlockput>
  end_op();
    80005842:	fffff097          	auipc	ra,0xfffff
    80005846:	b7a080e7          	jalr	-1158(ra) # 800043bc <end_op>
  return 0;
    8000584a:	4501                	li	a0,0
    8000584c:	a84d                	j	800058fe <sys_unlink+0x1c4>
    end_op();
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	b6e080e7          	jalr	-1170(ra) # 800043bc <end_op>
    return -1;
    80005856:	557d                	li	a0,-1
    80005858:	a05d                	j	800058fe <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000585a:	00003517          	auipc	a0,0x3
    8000585e:	eb650513          	addi	a0,a0,-330 # 80008710 <syscalls+0x2c0>
    80005862:	ffffb097          	auipc	ra,0xffffb
    80005866:	ce2080e7          	jalr	-798(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000586a:	04c92703          	lw	a4,76(s2)
    8000586e:	02000793          	li	a5,32
    80005872:	f6e7f9e3          	bgeu	a5,a4,800057e4 <sys_unlink+0xaa>
    80005876:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000587a:	4741                	li	a4,16
    8000587c:	86ce                	mv	a3,s3
    8000587e:	f1840613          	addi	a2,s0,-232
    80005882:	4581                	li	a1,0
    80005884:	854a                	mv	a0,s2
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	3a8080e7          	jalr	936(ra) # 80003c2e <readi>
    8000588e:	47c1                	li	a5,16
    80005890:	00f51b63          	bne	a0,a5,800058a6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005894:	f1845783          	lhu	a5,-232(s0)
    80005898:	e7a1                	bnez	a5,800058e0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000589a:	29c1                	addiw	s3,s3,16
    8000589c:	04c92783          	lw	a5,76(s2)
    800058a0:	fcf9ede3          	bltu	s3,a5,8000587a <sys_unlink+0x140>
    800058a4:	b781                	j	800057e4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058a6:	00003517          	auipc	a0,0x3
    800058aa:	e8250513          	addi	a0,a0,-382 # 80008728 <syscalls+0x2d8>
    800058ae:	ffffb097          	auipc	ra,0xffffb
    800058b2:	c96080e7          	jalr	-874(ra) # 80000544 <panic>
    panic("unlink: writei");
    800058b6:	00003517          	auipc	a0,0x3
    800058ba:	e8a50513          	addi	a0,a0,-374 # 80008740 <syscalls+0x2f0>
    800058be:	ffffb097          	auipc	ra,0xffffb
    800058c2:	c86080e7          	jalr	-890(ra) # 80000544 <panic>
    dp->nlink--;
    800058c6:	04a4d783          	lhu	a5,74(s1)
    800058ca:	37fd                	addiw	a5,a5,-1
    800058cc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800058d0:	8526                	mv	a0,s1
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	fde080e7          	jalr	-34(ra) # 800038b0 <iupdate>
    800058da:	b781                	j	8000581a <sys_unlink+0xe0>
    return -1;
    800058dc:	557d                	li	a0,-1
    800058de:	a005                	j	800058fe <sys_unlink+0x1c4>
    iunlockput(ip);
    800058e0:	854a                	mv	a0,s2
    800058e2:	ffffe097          	auipc	ra,0xffffe
    800058e6:	2fa080e7          	jalr	762(ra) # 80003bdc <iunlockput>
  iunlockput(dp);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	2f0080e7          	jalr	752(ra) # 80003bdc <iunlockput>
  end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	ac8080e7          	jalr	-1336(ra) # 800043bc <end_op>
  return -1;
    800058fc:	557d                	li	a0,-1
}
    800058fe:	70ae                	ld	ra,232(sp)
    80005900:	740e                	ld	s0,224(sp)
    80005902:	64ee                	ld	s1,216(sp)
    80005904:	694e                	ld	s2,208(sp)
    80005906:	69ae                	ld	s3,200(sp)
    80005908:	616d                	addi	sp,sp,240
    8000590a:	8082                	ret

000000008000590c <sys_open>:

uint64
sys_open(void)
{
    8000590c:	7131                	addi	sp,sp,-192
    8000590e:	fd06                	sd	ra,184(sp)
    80005910:	f922                	sd	s0,176(sp)
    80005912:	f526                	sd	s1,168(sp)
    80005914:	f14a                	sd	s2,160(sp)
    80005916:	ed4e                	sd	s3,152(sp)
    80005918:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000591a:	f4c40593          	addi	a1,s0,-180
    8000591e:	4505                	li	a0,1
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	476080e7          	jalr	1142(ra) # 80002d96 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005928:	08000613          	li	a2,128
    8000592c:	f5040593          	addi	a1,s0,-176
    80005930:	4501                	li	a0,0
    80005932:	ffffd097          	auipc	ra,0xffffd
    80005936:	4a4080e7          	jalr	1188(ra) # 80002dd6 <argstr>
    8000593a:	87aa                	mv	a5,a0
    return -1;
    8000593c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000593e:	0a07c963          	bltz	a5,800059f0 <sys_open+0xe4>

  begin_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	9fa080e7          	jalr	-1542(ra) # 8000433c <begin_op>

  if(omode & O_CREATE){
    8000594a:	f4c42783          	lw	a5,-180(s0)
    8000594e:	2007f793          	andi	a5,a5,512
    80005952:	cfc5                	beqz	a5,80005a0a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005954:	4681                	li	a3,0
    80005956:	4601                	li	a2,0
    80005958:	4589                	li	a1,2
    8000595a:	f5040513          	addi	a0,s0,-176
    8000595e:	00000097          	auipc	ra,0x0
    80005962:	974080e7          	jalr	-1676(ra) # 800052d2 <create>
    80005966:	84aa                	mv	s1,a0
    if(ip == 0){
    80005968:	c959                	beqz	a0,800059fe <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000596a:	04449703          	lh	a4,68(s1)
    8000596e:	478d                	li	a5,3
    80005970:	00f71763          	bne	a4,a5,8000597e <sys_open+0x72>
    80005974:	0464d703          	lhu	a4,70(s1)
    80005978:	47a5                	li	a5,9
    8000597a:	0ce7ed63          	bltu	a5,a4,80005a54 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000597e:	fffff097          	auipc	ra,0xfffff
    80005982:	dce080e7          	jalr	-562(ra) # 8000474c <filealloc>
    80005986:	89aa                	mv	s3,a0
    80005988:	10050363          	beqz	a0,80005a8e <sys_open+0x182>
    8000598c:	00000097          	auipc	ra,0x0
    80005990:	904080e7          	jalr	-1788(ra) # 80005290 <fdalloc>
    80005994:	892a                	mv	s2,a0
    80005996:	0e054763          	bltz	a0,80005a84 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000599a:	04449703          	lh	a4,68(s1)
    8000599e:	478d                	li	a5,3
    800059a0:	0cf70563          	beq	a4,a5,80005a6a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059a4:	4789                	li	a5,2
    800059a6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059aa:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059ae:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059b2:	f4c42783          	lw	a5,-180(s0)
    800059b6:	0017c713          	xori	a4,a5,1
    800059ba:	8b05                	andi	a4,a4,1
    800059bc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800059c0:	0037f713          	andi	a4,a5,3
    800059c4:	00e03733          	snez	a4,a4
    800059c8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800059cc:	4007f793          	andi	a5,a5,1024
    800059d0:	c791                	beqz	a5,800059dc <sys_open+0xd0>
    800059d2:	04449703          	lh	a4,68(s1)
    800059d6:	4789                	li	a5,2
    800059d8:	0af70063          	beq	a4,a5,80005a78 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	05e080e7          	jalr	94(ra) # 80003a3c <iunlock>
  end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	9d6080e7          	jalr	-1578(ra) # 800043bc <end_op>

  return fd;
    800059ee:	854a                	mv	a0,s2
}
    800059f0:	70ea                	ld	ra,184(sp)
    800059f2:	744a                	ld	s0,176(sp)
    800059f4:	74aa                	ld	s1,168(sp)
    800059f6:	790a                	ld	s2,160(sp)
    800059f8:	69ea                	ld	s3,152(sp)
    800059fa:	6129                	addi	sp,sp,192
    800059fc:	8082                	ret
      end_op();
    800059fe:	fffff097          	auipc	ra,0xfffff
    80005a02:	9be080e7          	jalr	-1602(ra) # 800043bc <end_op>
      return -1;
    80005a06:	557d                	li	a0,-1
    80005a08:	b7e5                	j	800059f0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a0a:	f5040513          	addi	a0,s0,-176
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	712080e7          	jalr	1810(ra) # 80004120 <namei>
    80005a16:	84aa                	mv	s1,a0
    80005a18:	c905                	beqz	a0,80005a48 <sys_open+0x13c>
    ilock(ip);
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	f60080e7          	jalr	-160(ra) # 8000397a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a22:	04449703          	lh	a4,68(s1)
    80005a26:	4785                	li	a5,1
    80005a28:	f4f711e3          	bne	a4,a5,8000596a <sys_open+0x5e>
    80005a2c:	f4c42783          	lw	a5,-180(s0)
    80005a30:	d7b9                	beqz	a5,8000597e <sys_open+0x72>
      iunlockput(ip);
    80005a32:	8526                	mv	a0,s1
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	1a8080e7          	jalr	424(ra) # 80003bdc <iunlockput>
      end_op();
    80005a3c:	fffff097          	auipc	ra,0xfffff
    80005a40:	980080e7          	jalr	-1664(ra) # 800043bc <end_op>
      return -1;
    80005a44:	557d                	li	a0,-1
    80005a46:	b76d                	j	800059f0 <sys_open+0xe4>
      end_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	974080e7          	jalr	-1676(ra) # 800043bc <end_op>
      return -1;
    80005a50:	557d                	li	a0,-1
    80005a52:	bf79                	j	800059f0 <sys_open+0xe4>
    iunlockput(ip);
    80005a54:	8526                	mv	a0,s1
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	186080e7          	jalr	390(ra) # 80003bdc <iunlockput>
    end_op();
    80005a5e:	fffff097          	auipc	ra,0xfffff
    80005a62:	95e080e7          	jalr	-1698(ra) # 800043bc <end_op>
    return -1;
    80005a66:	557d                	li	a0,-1
    80005a68:	b761                	j	800059f0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a6a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a6e:	04649783          	lh	a5,70(s1)
    80005a72:	02f99223          	sh	a5,36(s3)
    80005a76:	bf25                	j	800059ae <sys_open+0xa2>
    itrunc(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	00e080e7          	jalr	14(ra) # 80003a88 <itrunc>
    80005a82:	bfa9                	j	800059dc <sys_open+0xd0>
      fileclose(f);
    80005a84:	854e                	mv	a0,s3
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	d82080e7          	jalr	-638(ra) # 80004808 <fileclose>
    iunlockput(ip);
    80005a8e:	8526                	mv	a0,s1
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	14c080e7          	jalr	332(ra) # 80003bdc <iunlockput>
    end_op();
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	924080e7          	jalr	-1756(ra) # 800043bc <end_op>
    return -1;
    80005aa0:	557d                	li	a0,-1
    80005aa2:	b7b9                	j	800059f0 <sys_open+0xe4>

0000000080005aa4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005aa4:	7175                	addi	sp,sp,-144
    80005aa6:	e506                	sd	ra,136(sp)
    80005aa8:	e122                	sd	s0,128(sp)
    80005aaa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	890080e7          	jalr	-1904(ra) # 8000433c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ab4:	08000613          	li	a2,128
    80005ab8:	f7040593          	addi	a1,s0,-144
    80005abc:	4501                	li	a0,0
    80005abe:	ffffd097          	auipc	ra,0xffffd
    80005ac2:	318080e7          	jalr	792(ra) # 80002dd6 <argstr>
    80005ac6:	02054963          	bltz	a0,80005af8 <sys_mkdir+0x54>
    80005aca:	4681                	li	a3,0
    80005acc:	4601                	li	a2,0
    80005ace:	4585                	li	a1,1
    80005ad0:	f7040513          	addi	a0,s0,-144
    80005ad4:	fffff097          	auipc	ra,0xfffff
    80005ad8:	7fe080e7          	jalr	2046(ra) # 800052d2 <create>
    80005adc:	cd11                	beqz	a0,80005af8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ade:	ffffe097          	auipc	ra,0xffffe
    80005ae2:	0fe080e7          	jalr	254(ra) # 80003bdc <iunlockput>
  end_op();
    80005ae6:	fffff097          	auipc	ra,0xfffff
    80005aea:	8d6080e7          	jalr	-1834(ra) # 800043bc <end_op>
  return 0;
    80005aee:	4501                	li	a0,0
}
    80005af0:	60aa                	ld	ra,136(sp)
    80005af2:	640a                	ld	s0,128(sp)
    80005af4:	6149                	addi	sp,sp,144
    80005af6:	8082                	ret
    end_op();
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	8c4080e7          	jalr	-1852(ra) # 800043bc <end_op>
    return -1;
    80005b00:	557d                	li	a0,-1
    80005b02:	b7fd                	j	80005af0 <sys_mkdir+0x4c>

0000000080005b04 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b04:	7135                	addi	sp,sp,-160
    80005b06:	ed06                	sd	ra,152(sp)
    80005b08:	e922                	sd	s0,144(sp)
    80005b0a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b0c:	fffff097          	auipc	ra,0xfffff
    80005b10:	830080e7          	jalr	-2000(ra) # 8000433c <begin_op>
  argint(1, &major);
    80005b14:	f6c40593          	addi	a1,s0,-148
    80005b18:	4505                	li	a0,1
    80005b1a:	ffffd097          	auipc	ra,0xffffd
    80005b1e:	27c080e7          	jalr	636(ra) # 80002d96 <argint>
  argint(2, &minor);
    80005b22:	f6840593          	addi	a1,s0,-152
    80005b26:	4509                	li	a0,2
    80005b28:	ffffd097          	auipc	ra,0xffffd
    80005b2c:	26e080e7          	jalr	622(ra) # 80002d96 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b30:	08000613          	li	a2,128
    80005b34:	f7040593          	addi	a1,s0,-144
    80005b38:	4501                	li	a0,0
    80005b3a:	ffffd097          	auipc	ra,0xffffd
    80005b3e:	29c080e7          	jalr	668(ra) # 80002dd6 <argstr>
    80005b42:	02054b63          	bltz	a0,80005b78 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b46:	f6841683          	lh	a3,-152(s0)
    80005b4a:	f6c41603          	lh	a2,-148(s0)
    80005b4e:	458d                	li	a1,3
    80005b50:	f7040513          	addi	a0,s0,-144
    80005b54:	fffff097          	auipc	ra,0xfffff
    80005b58:	77e080e7          	jalr	1918(ra) # 800052d2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b5c:	cd11                	beqz	a0,80005b78 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b5e:	ffffe097          	auipc	ra,0xffffe
    80005b62:	07e080e7          	jalr	126(ra) # 80003bdc <iunlockput>
  end_op();
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	856080e7          	jalr	-1962(ra) # 800043bc <end_op>
  return 0;
    80005b6e:	4501                	li	a0,0
}
    80005b70:	60ea                	ld	ra,152(sp)
    80005b72:	644a                	ld	s0,144(sp)
    80005b74:	610d                	addi	sp,sp,160
    80005b76:	8082                	ret
    end_op();
    80005b78:	fffff097          	auipc	ra,0xfffff
    80005b7c:	844080e7          	jalr	-1980(ra) # 800043bc <end_op>
    return -1;
    80005b80:	557d                	li	a0,-1
    80005b82:	b7fd                	j	80005b70 <sys_mknod+0x6c>

0000000080005b84 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b84:	7135                	addi	sp,sp,-160
    80005b86:	ed06                	sd	ra,152(sp)
    80005b88:	e922                	sd	s0,144(sp)
    80005b8a:	e526                	sd	s1,136(sp)
    80005b8c:	e14a                	sd	s2,128(sp)
    80005b8e:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b90:	ffffc097          	auipc	ra,0xffffc
    80005b94:	e36080e7          	jalr	-458(ra) # 800019c6 <myproc>
    80005b98:	892a                	mv	s2,a0
  
  begin_op();
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	7a2080e7          	jalr	1954(ra) # 8000433c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ba2:	08000613          	li	a2,128
    80005ba6:	f6040593          	addi	a1,s0,-160
    80005baa:	4501                	li	a0,0
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	22a080e7          	jalr	554(ra) # 80002dd6 <argstr>
    80005bb4:	04054b63          	bltz	a0,80005c0a <sys_chdir+0x86>
    80005bb8:	f6040513          	addi	a0,s0,-160
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	564080e7          	jalr	1380(ra) # 80004120 <namei>
    80005bc4:	84aa                	mv	s1,a0
    80005bc6:	c131                	beqz	a0,80005c0a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	db2080e7          	jalr	-590(ra) # 8000397a <ilock>
  if(ip->type != T_DIR){
    80005bd0:	04449703          	lh	a4,68(s1)
    80005bd4:	4785                	li	a5,1
    80005bd6:	04f71063          	bne	a4,a5,80005c16 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005bda:	8526                	mv	a0,s1
    80005bdc:	ffffe097          	auipc	ra,0xffffe
    80005be0:	e60080e7          	jalr	-416(ra) # 80003a3c <iunlock>
  iput(p->cwd);
    80005be4:	15093503          	ld	a0,336(s2)
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	f4c080e7          	jalr	-180(ra) # 80003b34 <iput>
  end_op();
    80005bf0:	ffffe097          	auipc	ra,0xffffe
    80005bf4:	7cc080e7          	jalr	1996(ra) # 800043bc <end_op>
  p->cwd = ip;
    80005bf8:	14993823          	sd	s1,336(s2)
  return 0;
    80005bfc:	4501                	li	a0,0
}
    80005bfe:	60ea                	ld	ra,152(sp)
    80005c00:	644a                	ld	s0,144(sp)
    80005c02:	64aa                	ld	s1,136(sp)
    80005c04:	690a                	ld	s2,128(sp)
    80005c06:	610d                	addi	sp,sp,160
    80005c08:	8082                	ret
    end_op();
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	7b2080e7          	jalr	1970(ra) # 800043bc <end_op>
    return -1;
    80005c12:	557d                	li	a0,-1
    80005c14:	b7ed                	j	80005bfe <sys_chdir+0x7a>
    iunlockput(ip);
    80005c16:	8526                	mv	a0,s1
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	fc4080e7          	jalr	-60(ra) # 80003bdc <iunlockput>
    end_op();
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	79c080e7          	jalr	1948(ra) # 800043bc <end_op>
    return -1;
    80005c28:	557d                	li	a0,-1
    80005c2a:	bfd1                	j	80005bfe <sys_chdir+0x7a>

0000000080005c2c <sys_exec>:

uint64
sys_exec(void)
{
    80005c2c:	7145                	addi	sp,sp,-464
    80005c2e:	e786                	sd	ra,456(sp)
    80005c30:	e3a2                	sd	s0,448(sp)
    80005c32:	ff26                	sd	s1,440(sp)
    80005c34:	fb4a                	sd	s2,432(sp)
    80005c36:	f74e                	sd	s3,424(sp)
    80005c38:	f352                	sd	s4,416(sp)
    80005c3a:	ef56                	sd	s5,408(sp)
    80005c3c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c3e:	e3840593          	addi	a1,s0,-456
    80005c42:	4505                	li	a0,1
    80005c44:	ffffd097          	auipc	ra,0xffffd
    80005c48:	172080e7          	jalr	370(ra) # 80002db6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c4c:	08000613          	li	a2,128
    80005c50:	f4040593          	addi	a1,s0,-192
    80005c54:	4501                	li	a0,0
    80005c56:	ffffd097          	auipc	ra,0xffffd
    80005c5a:	180080e7          	jalr	384(ra) # 80002dd6 <argstr>
    80005c5e:	87aa                	mv	a5,a0
    return -1;
    80005c60:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c62:	0c07c263          	bltz	a5,80005d26 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c66:	10000613          	li	a2,256
    80005c6a:	4581                	li	a1,0
    80005c6c:	e4040513          	addi	a0,s0,-448
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	076080e7          	jalr	118(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c78:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c7c:	89a6                	mv	s3,s1
    80005c7e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c80:	02000a13          	li	s4,32
    80005c84:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c88:	00391513          	slli	a0,s2,0x3
    80005c8c:	e3040593          	addi	a1,s0,-464
    80005c90:	e3843783          	ld	a5,-456(s0)
    80005c94:	953e                	add	a0,a0,a5
    80005c96:	ffffd097          	auipc	ra,0xffffd
    80005c9a:	062080e7          	jalr	98(ra) # 80002cf8 <fetchaddr>
    80005c9e:	02054a63          	bltz	a0,80005cd2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ca2:	e3043783          	ld	a5,-464(s0)
    80005ca6:	c3b9                	beqz	a5,80005cec <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ca8:	ffffb097          	auipc	ra,0xffffb
    80005cac:	e52080e7          	jalr	-430(ra) # 80000afa <kalloc>
    80005cb0:	85aa                	mv	a1,a0
    80005cb2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cb6:	cd11                	beqz	a0,80005cd2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cb8:	6605                	lui	a2,0x1
    80005cba:	e3043503          	ld	a0,-464(s0)
    80005cbe:	ffffd097          	auipc	ra,0xffffd
    80005cc2:	08c080e7          	jalr	140(ra) # 80002d4a <fetchstr>
    80005cc6:	00054663          	bltz	a0,80005cd2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005cca:	0905                	addi	s2,s2,1
    80005ccc:	09a1                	addi	s3,s3,8
    80005cce:	fb491be3          	bne	s2,s4,80005c84 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cd2:	10048913          	addi	s2,s1,256
    80005cd6:	6088                	ld	a0,0(s1)
    80005cd8:	c531                	beqz	a0,80005d24 <sys_exec+0xf8>
    kfree(argv[i]);
    80005cda:	ffffb097          	auipc	ra,0xffffb
    80005cde:	d24080e7          	jalr	-732(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ce2:	04a1                	addi	s1,s1,8
    80005ce4:	ff2499e3          	bne	s1,s2,80005cd6 <sys_exec+0xaa>
  return -1;
    80005ce8:	557d                	li	a0,-1
    80005cea:	a835                	j	80005d26 <sys_exec+0xfa>
      argv[i] = 0;
    80005cec:	0a8e                	slli	s5,s5,0x3
    80005cee:	fc040793          	addi	a5,s0,-64
    80005cf2:	9abe                	add	s5,s5,a5
    80005cf4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005cf8:	e4040593          	addi	a1,s0,-448
    80005cfc:	f4040513          	addi	a0,s0,-192
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	190080e7          	jalr	400(ra) # 80004e90 <exec>
    80005d08:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d0a:	10048993          	addi	s3,s1,256
    80005d0e:	6088                	ld	a0,0(s1)
    80005d10:	c901                	beqz	a0,80005d20 <sys_exec+0xf4>
    kfree(argv[i]);
    80005d12:	ffffb097          	auipc	ra,0xffffb
    80005d16:	cec080e7          	jalr	-788(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d1a:	04a1                	addi	s1,s1,8
    80005d1c:	ff3499e3          	bne	s1,s3,80005d0e <sys_exec+0xe2>
  return ret;
    80005d20:	854a                	mv	a0,s2
    80005d22:	a011                	j	80005d26 <sys_exec+0xfa>
  return -1;
    80005d24:	557d                	li	a0,-1
}
    80005d26:	60be                	ld	ra,456(sp)
    80005d28:	641e                	ld	s0,448(sp)
    80005d2a:	74fa                	ld	s1,440(sp)
    80005d2c:	795a                	ld	s2,432(sp)
    80005d2e:	79ba                	ld	s3,424(sp)
    80005d30:	7a1a                	ld	s4,416(sp)
    80005d32:	6afa                	ld	s5,408(sp)
    80005d34:	6179                	addi	sp,sp,464
    80005d36:	8082                	ret

0000000080005d38 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d38:	7139                	addi	sp,sp,-64
    80005d3a:	fc06                	sd	ra,56(sp)
    80005d3c:	f822                	sd	s0,48(sp)
    80005d3e:	f426                	sd	s1,40(sp)
    80005d40:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d42:	ffffc097          	auipc	ra,0xffffc
    80005d46:	c84080e7          	jalr	-892(ra) # 800019c6 <myproc>
    80005d4a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d4c:	fd840593          	addi	a1,s0,-40
    80005d50:	4501                	li	a0,0
    80005d52:	ffffd097          	auipc	ra,0xffffd
    80005d56:	064080e7          	jalr	100(ra) # 80002db6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d5a:	fc840593          	addi	a1,s0,-56
    80005d5e:	fd040513          	addi	a0,s0,-48
    80005d62:	fffff097          	auipc	ra,0xfffff
    80005d66:	dd6080e7          	jalr	-554(ra) # 80004b38 <pipealloc>
    return -1;
    80005d6a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d6c:	0c054463          	bltz	a0,80005e34 <sys_pipe+0xfc>
  fd0 = -1;
    80005d70:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d74:	fd043503          	ld	a0,-48(s0)
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	518080e7          	jalr	1304(ra) # 80005290 <fdalloc>
    80005d80:	fca42223          	sw	a0,-60(s0)
    80005d84:	08054b63          	bltz	a0,80005e1a <sys_pipe+0xe2>
    80005d88:	fc843503          	ld	a0,-56(s0)
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	504080e7          	jalr	1284(ra) # 80005290 <fdalloc>
    80005d94:	fca42023          	sw	a0,-64(s0)
    80005d98:	06054863          	bltz	a0,80005e08 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d9c:	4691                	li	a3,4
    80005d9e:	fc440613          	addi	a2,s0,-60
    80005da2:	fd843583          	ld	a1,-40(s0)
    80005da6:	68a8                	ld	a0,80(s1)
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	8dc080e7          	jalr	-1828(ra) # 80001684 <copyout>
    80005db0:	02054063          	bltz	a0,80005dd0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005db4:	4691                	li	a3,4
    80005db6:	fc040613          	addi	a2,s0,-64
    80005dba:	fd843583          	ld	a1,-40(s0)
    80005dbe:	0591                	addi	a1,a1,4
    80005dc0:	68a8                	ld	a0,80(s1)
    80005dc2:	ffffc097          	auipc	ra,0xffffc
    80005dc6:	8c2080e7          	jalr	-1854(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005dca:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005dcc:	06055463          	bgez	a0,80005e34 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005dd0:	fc442783          	lw	a5,-60(s0)
    80005dd4:	07e9                	addi	a5,a5,26
    80005dd6:	078e                	slli	a5,a5,0x3
    80005dd8:	97a6                	add	a5,a5,s1
    80005dda:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005dde:	fc042503          	lw	a0,-64(s0)
    80005de2:	0569                	addi	a0,a0,26
    80005de4:	050e                	slli	a0,a0,0x3
    80005de6:	94aa                	add	s1,s1,a0
    80005de8:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dec:	fd043503          	ld	a0,-48(s0)
    80005df0:	fffff097          	auipc	ra,0xfffff
    80005df4:	a18080e7          	jalr	-1512(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005df8:	fc843503          	ld	a0,-56(s0)
    80005dfc:	fffff097          	auipc	ra,0xfffff
    80005e00:	a0c080e7          	jalr	-1524(ra) # 80004808 <fileclose>
    return -1;
    80005e04:	57fd                	li	a5,-1
    80005e06:	a03d                	j	80005e34 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e08:	fc442783          	lw	a5,-60(s0)
    80005e0c:	0007c763          	bltz	a5,80005e1a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e10:	07e9                	addi	a5,a5,26
    80005e12:	078e                	slli	a5,a5,0x3
    80005e14:	94be                	add	s1,s1,a5
    80005e16:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e1a:	fd043503          	ld	a0,-48(s0)
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	9ea080e7          	jalr	-1558(ra) # 80004808 <fileclose>
    fileclose(wf);
    80005e26:	fc843503          	ld	a0,-56(s0)
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	9de080e7          	jalr	-1570(ra) # 80004808 <fileclose>
    return -1;
    80005e32:	57fd                	li	a5,-1
}
    80005e34:	853e                	mv	a0,a5
    80005e36:	70e2                	ld	ra,56(sp)
    80005e38:	7442                	ld	s0,48(sp)
    80005e3a:	74a2                	ld	s1,40(sp)
    80005e3c:	6121                	addi	sp,sp,64
    80005e3e:	8082                	ret

0000000080005e40 <kernelvec>:
    80005e40:	7111                	addi	sp,sp,-256
    80005e42:	e006                	sd	ra,0(sp)
    80005e44:	e40a                	sd	sp,8(sp)
    80005e46:	e80e                	sd	gp,16(sp)
    80005e48:	ec12                	sd	tp,24(sp)
    80005e4a:	f016                	sd	t0,32(sp)
    80005e4c:	f41a                	sd	t1,40(sp)
    80005e4e:	f81e                	sd	t2,48(sp)
    80005e50:	fc22                	sd	s0,56(sp)
    80005e52:	e0a6                	sd	s1,64(sp)
    80005e54:	e4aa                	sd	a0,72(sp)
    80005e56:	e8ae                	sd	a1,80(sp)
    80005e58:	ecb2                	sd	a2,88(sp)
    80005e5a:	f0b6                	sd	a3,96(sp)
    80005e5c:	f4ba                	sd	a4,104(sp)
    80005e5e:	f8be                	sd	a5,112(sp)
    80005e60:	fcc2                	sd	a6,120(sp)
    80005e62:	e146                	sd	a7,128(sp)
    80005e64:	e54a                	sd	s2,136(sp)
    80005e66:	e94e                	sd	s3,144(sp)
    80005e68:	ed52                	sd	s4,152(sp)
    80005e6a:	f156                	sd	s5,160(sp)
    80005e6c:	f55a                	sd	s6,168(sp)
    80005e6e:	f95e                	sd	s7,176(sp)
    80005e70:	fd62                	sd	s8,184(sp)
    80005e72:	e1e6                	sd	s9,192(sp)
    80005e74:	e5ea                	sd	s10,200(sp)
    80005e76:	e9ee                	sd	s11,208(sp)
    80005e78:	edf2                	sd	t3,216(sp)
    80005e7a:	f1f6                	sd	t4,224(sp)
    80005e7c:	f5fa                	sd	t5,232(sp)
    80005e7e:	f9fe                	sd	t6,240(sp)
    80005e80:	d45fc0ef          	jal	ra,80002bc4 <kerneltrap>
    80005e84:	6082                	ld	ra,0(sp)
    80005e86:	6122                	ld	sp,8(sp)
    80005e88:	61c2                	ld	gp,16(sp)
    80005e8a:	7282                	ld	t0,32(sp)
    80005e8c:	7322                	ld	t1,40(sp)
    80005e8e:	73c2                	ld	t2,48(sp)
    80005e90:	7462                	ld	s0,56(sp)
    80005e92:	6486                	ld	s1,64(sp)
    80005e94:	6526                	ld	a0,72(sp)
    80005e96:	65c6                	ld	a1,80(sp)
    80005e98:	6666                	ld	a2,88(sp)
    80005e9a:	7686                	ld	a3,96(sp)
    80005e9c:	7726                	ld	a4,104(sp)
    80005e9e:	77c6                	ld	a5,112(sp)
    80005ea0:	7866                	ld	a6,120(sp)
    80005ea2:	688a                	ld	a7,128(sp)
    80005ea4:	692a                	ld	s2,136(sp)
    80005ea6:	69ca                	ld	s3,144(sp)
    80005ea8:	6a6a                	ld	s4,152(sp)
    80005eaa:	7a8a                	ld	s5,160(sp)
    80005eac:	7b2a                	ld	s6,168(sp)
    80005eae:	7bca                	ld	s7,176(sp)
    80005eb0:	7c6a                	ld	s8,184(sp)
    80005eb2:	6c8e                	ld	s9,192(sp)
    80005eb4:	6d2e                	ld	s10,200(sp)
    80005eb6:	6dce                	ld	s11,208(sp)
    80005eb8:	6e6e                	ld	t3,216(sp)
    80005eba:	7e8e                	ld	t4,224(sp)
    80005ebc:	7f2e                	ld	t5,232(sp)
    80005ebe:	7fce                	ld	t6,240(sp)
    80005ec0:	6111                	addi	sp,sp,256
    80005ec2:	10200073          	sret
    80005ec6:	00000013          	nop
    80005eca:	00000013          	nop
    80005ece:	0001                	nop

0000000080005ed0 <timervec>:
    80005ed0:	34051573          	csrrw	a0,mscratch,a0
    80005ed4:	e10c                	sd	a1,0(a0)
    80005ed6:	e510                	sd	a2,8(a0)
    80005ed8:	e914                	sd	a3,16(a0)
    80005eda:	6d0c                	ld	a1,24(a0)
    80005edc:	7110                	ld	a2,32(a0)
    80005ede:	6194                	ld	a3,0(a1)
    80005ee0:	96b2                	add	a3,a3,a2
    80005ee2:	e194                	sd	a3,0(a1)
    80005ee4:	4589                	li	a1,2
    80005ee6:	14459073          	csrw	sip,a1
    80005eea:	6914                	ld	a3,16(a0)
    80005eec:	6510                	ld	a2,8(a0)
    80005eee:	610c                	ld	a1,0(a0)
    80005ef0:	34051573          	csrrw	a0,mscratch,a0
    80005ef4:	30200073          	mret
	...

0000000080005efa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005efa:	1141                	addi	sp,sp,-16
    80005efc:	e422                	sd	s0,8(sp)
    80005efe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f00:	0c0007b7          	lui	a5,0xc000
    80005f04:	4705                	li	a4,1
    80005f06:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f08:	c3d8                	sw	a4,4(a5)
}
    80005f0a:	6422                	ld	s0,8(sp)
    80005f0c:	0141                	addi	sp,sp,16
    80005f0e:	8082                	ret

0000000080005f10 <plicinithart>:

void
plicinithart(void)
{
    80005f10:	1141                	addi	sp,sp,-16
    80005f12:	e406                	sd	ra,8(sp)
    80005f14:	e022                	sd	s0,0(sp)
    80005f16:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f18:	ffffc097          	auipc	ra,0xffffc
    80005f1c:	a82080e7          	jalr	-1406(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f20:	0085171b          	slliw	a4,a0,0x8
    80005f24:	0c0027b7          	lui	a5,0xc002
    80005f28:	97ba                	add	a5,a5,a4
    80005f2a:	40200713          	li	a4,1026
    80005f2e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f32:	00d5151b          	slliw	a0,a0,0xd
    80005f36:	0c2017b7          	lui	a5,0xc201
    80005f3a:	953e                	add	a0,a0,a5
    80005f3c:	00052023          	sw	zero,0(a0)
}
    80005f40:	60a2                	ld	ra,8(sp)
    80005f42:	6402                	ld	s0,0(sp)
    80005f44:	0141                	addi	sp,sp,16
    80005f46:	8082                	ret

0000000080005f48 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f48:	1141                	addi	sp,sp,-16
    80005f4a:	e406                	sd	ra,8(sp)
    80005f4c:	e022                	sd	s0,0(sp)
    80005f4e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f50:	ffffc097          	auipc	ra,0xffffc
    80005f54:	a4a080e7          	jalr	-1462(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f58:	00d5179b          	slliw	a5,a0,0xd
    80005f5c:	0c201537          	lui	a0,0xc201
    80005f60:	953e                	add	a0,a0,a5
  return irq;
}
    80005f62:	4148                	lw	a0,4(a0)
    80005f64:	60a2                	ld	ra,8(sp)
    80005f66:	6402                	ld	s0,0(sp)
    80005f68:	0141                	addi	sp,sp,16
    80005f6a:	8082                	ret

0000000080005f6c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f6c:	1101                	addi	sp,sp,-32
    80005f6e:	ec06                	sd	ra,24(sp)
    80005f70:	e822                	sd	s0,16(sp)
    80005f72:	e426                	sd	s1,8(sp)
    80005f74:	1000                	addi	s0,sp,32
    80005f76:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f78:	ffffc097          	auipc	ra,0xffffc
    80005f7c:	a22080e7          	jalr	-1502(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f80:	00d5151b          	slliw	a0,a0,0xd
    80005f84:	0c2017b7          	lui	a5,0xc201
    80005f88:	97aa                	add	a5,a5,a0
    80005f8a:	c3c4                	sw	s1,4(a5)
}
    80005f8c:	60e2                	ld	ra,24(sp)
    80005f8e:	6442                	ld	s0,16(sp)
    80005f90:	64a2                	ld	s1,8(sp)
    80005f92:	6105                	addi	sp,sp,32
    80005f94:	8082                	ret

0000000080005f96 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f96:	1141                	addi	sp,sp,-16
    80005f98:	e406                	sd	ra,8(sp)
    80005f9a:	e022                	sd	s0,0(sp)
    80005f9c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f9e:	479d                	li	a5,7
    80005fa0:	04a7cc63          	blt	a5,a0,80005ff8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005fa4:	0001c797          	auipc	a5,0x1c
    80005fa8:	c6c78793          	addi	a5,a5,-916 # 80021c10 <disk>
    80005fac:	97aa                	add	a5,a5,a0
    80005fae:	0187c783          	lbu	a5,24(a5)
    80005fb2:	ebb9                	bnez	a5,80006008 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005fb4:	00451613          	slli	a2,a0,0x4
    80005fb8:	0001c797          	auipc	a5,0x1c
    80005fbc:	c5878793          	addi	a5,a5,-936 # 80021c10 <disk>
    80005fc0:	6394                	ld	a3,0(a5)
    80005fc2:	96b2                	add	a3,a3,a2
    80005fc4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005fc8:	6398                	ld	a4,0(a5)
    80005fca:	9732                	add	a4,a4,a2
    80005fcc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005fd0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005fd4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005fd8:	953e                	add	a0,a0,a5
    80005fda:	4785                	li	a5,1
    80005fdc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005fe0:	0001c517          	auipc	a0,0x1c
    80005fe4:	c4850513          	addi	a0,a0,-952 # 80021c28 <disk+0x18>
    80005fe8:	ffffc097          	auipc	ra,0xffffc
    80005fec:	0e6080e7          	jalr	230(ra) # 800020ce <wakeup>
}
    80005ff0:	60a2                	ld	ra,8(sp)
    80005ff2:	6402                	ld	s0,0(sp)
    80005ff4:	0141                	addi	sp,sp,16
    80005ff6:	8082                	ret
    panic("free_desc 1");
    80005ff8:	00002517          	auipc	a0,0x2
    80005ffc:	75850513          	addi	a0,a0,1880 # 80008750 <syscalls+0x300>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006008:	00002517          	auipc	a0,0x2
    8000600c:	75850513          	addi	a0,a0,1880 # 80008760 <syscalls+0x310>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	534080e7          	jalr	1332(ra) # 80000544 <panic>

0000000080006018 <virtio_disk_init>:
{
    80006018:	1101                	addi	sp,sp,-32
    8000601a:	ec06                	sd	ra,24(sp)
    8000601c:	e822                	sd	s0,16(sp)
    8000601e:	e426                	sd	s1,8(sp)
    80006020:	e04a                	sd	s2,0(sp)
    80006022:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006024:	00002597          	auipc	a1,0x2
    80006028:	74c58593          	addi	a1,a1,1868 # 80008770 <syscalls+0x320>
    8000602c:	0001c517          	auipc	a0,0x1c
    80006030:	d0c50513          	addi	a0,a0,-756 # 80021d38 <disk+0x128>
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	b26080e7          	jalr	-1242(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000603c:	100017b7          	lui	a5,0x10001
    80006040:	4398                	lw	a4,0(a5)
    80006042:	2701                	sext.w	a4,a4
    80006044:	747277b7          	lui	a5,0x74727
    80006048:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000604c:	14f71e63          	bne	a4,a5,800061a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006050:	100017b7          	lui	a5,0x10001
    80006054:	43dc                	lw	a5,4(a5)
    80006056:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006058:	4709                	li	a4,2
    8000605a:	14e79763          	bne	a5,a4,800061a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000605e:	100017b7          	lui	a5,0x10001
    80006062:	479c                	lw	a5,8(a5)
    80006064:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006066:	14e79163          	bne	a5,a4,800061a8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000606a:	100017b7          	lui	a5,0x10001
    8000606e:	47d8                	lw	a4,12(a5)
    80006070:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006072:	554d47b7          	lui	a5,0x554d4
    80006076:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000607a:	12f71763          	bne	a4,a5,800061a8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000607e:	100017b7          	lui	a5,0x10001
    80006082:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006086:	4705                	li	a4,1
    80006088:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000608a:	470d                	li	a4,3
    8000608c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000608e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006090:	c7ffe737          	lui	a4,0xc7ffe
    80006094:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdca0f>
    80006098:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000609a:	2701                	sext.w	a4,a4
    8000609c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000609e:	472d                	li	a4,11
    800060a0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060a2:	0707a903          	lw	s2,112(a5)
    800060a6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060a8:	00897793          	andi	a5,s2,8
    800060ac:	10078663          	beqz	a5,800061b8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060b0:	100017b7          	lui	a5,0x10001
    800060b4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800060b8:	43fc                	lw	a5,68(a5)
    800060ba:	2781                	sext.w	a5,a5
    800060bc:	10079663          	bnez	a5,800061c8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800060c0:	100017b7          	lui	a5,0x10001
    800060c4:	5bdc                	lw	a5,52(a5)
    800060c6:	2781                	sext.w	a5,a5
  if(max == 0)
    800060c8:	10078863          	beqz	a5,800061d8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    800060cc:	471d                	li	a4,7
    800060ce:	10f77d63          	bgeu	a4,a5,800061e8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    800060d2:	ffffb097          	auipc	ra,0xffffb
    800060d6:	a28080e7          	jalr	-1496(ra) # 80000afa <kalloc>
    800060da:	0001c497          	auipc	s1,0x1c
    800060de:	b3648493          	addi	s1,s1,-1226 # 80021c10 <disk>
    800060e2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800060e4:	ffffb097          	auipc	ra,0xffffb
    800060e8:	a16080e7          	jalr	-1514(ra) # 80000afa <kalloc>
    800060ec:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800060ee:	ffffb097          	auipc	ra,0xffffb
    800060f2:	a0c080e7          	jalr	-1524(ra) # 80000afa <kalloc>
    800060f6:	87aa                	mv	a5,a0
    800060f8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060fa:	6088                	ld	a0,0(s1)
    800060fc:	cd75                	beqz	a0,800061f8 <virtio_disk_init+0x1e0>
    800060fe:	0001c717          	auipc	a4,0x1c
    80006102:	b1a73703          	ld	a4,-1254(a4) # 80021c18 <disk+0x8>
    80006106:	cb6d                	beqz	a4,800061f8 <virtio_disk_init+0x1e0>
    80006108:	cbe5                	beqz	a5,800061f8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000610a:	6605                	lui	a2,0x1
    8000610c:	4581                	li	a1,0
    8000610e:	ffffb097          	auipc	ra,0xffffb
    80006112:	bd8080e7          	jalr	-1064(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006116:	0001c497          	auipc	s1,0x1c
    8000611a:	afa48493          	addi	s1,s1,-1286 # 80021c10 <disk>
    8000611e:	6605                	lui	a2,0x1
    80006120:	4581                	li	a1,0
    80006122:	6488                	ld	a0,8(s1)
    80006124:	ffffb097          	auipc	ra,0xffffb
    80006128:	bc2080e7          	jalr	-1086(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000612c:	6605                	lui	a2,0x1
    8000612e:	4581                	li	a1,0
    80006130:	6888                	ld	a0,16(s1)
    80006132:	ffffb097          	auipc	ra,0xffffb
    80006136:	bb4080e7          	jalr	-1100(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000613a:	100017b7          	lui	a5,0x10001
    8000613e:	4721                	li	a4,8
    80006140:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006142:	4098                	lw	a4,0(s1)
    80006144:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006148:	40d8                	lw	a4,4(s1)
    8000614a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000614e:	6498                	ld	a4,8(s1)
    80006150:	0007069b          	sext.w	a3,a4
    80006154:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006158:	9701                	srai	a4,a4,0x20
    8000615a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000615e:	6898                	ld	a4,16(s1)
    80006160:	0007069b          	sext.w	a3,a4
    80006164:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006168:	9701                	srai	a4,a4,0x20
    8000616a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000616e:	4685                	li	a3,1
    80006170:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006172:	4705                	li	a4,1
    80006174:	00d48c23          	sb	a3,24(s1)
    80006178:	00e48ca3          	sb	a4,25(s1)
    8000617c:	00e48d23          	sb	a4,26(s1)
    80006180:	00e48da3          	sb	a4,27(s1)
    80006184:	00e48e23          	sb	a4,28(s1)
    80006188:	00e48ea3          	sb	a4,29(s1)
    8000618c:	00e48f23          	sb	a4,30(s1)
    80006190:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006194:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006198:	0727a823          	sw	s2,112(a5)
}
    8000619c:	60e2                	ld	ra,24(sp)
    8000619e:	6442                	ld	s0,16(sp)
    800061a0:	64a2                	ld	s1,8(sp)
    800061a2:	6902                	ld	s2,0(sp)
    800061a4:	6105                	addi	sp,sp,32
    800061a6:	8082                	ret
    panic("could not find virtio disk");
    800061a8:	00002517          	auipc	a0,0x2
    800061ac:	5d850513          	addi	a0,a0,1496 # 80008780 <syscalls+0x330>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	394080e7          	jalr	916(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	5e850513          	addi	a0,a0,1512 # 800087a0 <syscalls+0x350>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	384080e7          	jalr	900(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800061c8:	00002517          	auipc	a0,0x2
    800061cc:	5f850513          	addi	a0,a0,1528 # 800087c0 <syscalls+0x370>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	374080e7          	jalr	884(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800061d8:	00002517          	auipc	a0,0x2
    800061dc:	60850513          	addi	a0,a0,1544 # 800087e0 <syscalls+0x390>
    800061e0:	ffffa097          	auipc	ra,0xffffa
    800061e4:	364080e7          	jalr	868(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800061e8:	00002517          	auipc	a0,0x2
    800061ec:	61850513          	addi	a0,a0,1560 # 80008800 <syscalls+0x3b0>
    800061f0:	ffffa097          	auipc	ra,0xffffa
    800061f4:	354080e7          	jalr	852(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800061f8:	00002517          	auipc	a0,0x2
    800061fc:	62850513          	addi	a0,a0,1576 # 80008820 <syscalls+0x3d0>
    80006200:	ffffa097          	auipc	ra,0xffffa
    80006204:	344080e7          	jalr	836(ra) # 80000544 <panic>

0000000080006208 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006208:	7159                	addi	sp,sp,-112
    8000620a:	f486                	sd	ra,104(sp)
    8000620c:	f0a2                	sd	s0,96(sp)
    8000620e:	eca6                	sd	s1,88(sp)
    80006210:	e8ca                	sd	s2,80(sp)
    80006212:	e4ce                	sd	s3,72(sp)
    80006214:	e0d2                	sd	s4,64(sp)
    80006216:	fc56                	sd	s5,56(sp)
    80006218:	f85a                	sd	s6,48(sp)
    8000621a:	f45e                	sd	s7,40(sp)
    8000621c:	f062                	sd	s8,32(sp)
    8000621e:	ec66                	sd	s9,24(sp)
    80006220:	e86a                	sd	s10,16(sp)
    80006222:	1880                	addi	s0,sp,112
    80006224:	892a                	mv	s2,a0
    80006226:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006228:	00c52c83          	lw	s9,12(a0)
    8000622c:	001c9c9b          	slliw	s9,s9,0x1
    80006230:	1c82                	slli	s9,s9,0x20
    80006232:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006236:	0001c517          	auipc	a0,0x1c
    8000623a:	b0250513          	addi	a0,a0,-1278 # 80021d38 <disk+0x128>
    8000623e:	ffffb097          	auipc	ra,0xffffb
    80006242:	9ac080e7          	jalr	-1620(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006246:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006248:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000624a:	0001cb17          	auipc	s6,0x1c
    8000624e:	9c6b0b13          	addi	s6,s6,-1594 # 80021c10 <disk>
  for(int i = 0; i < 3; i++){
    80006252:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006254:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006256:	0001cc17          	auipc	s8,0x1c
    8000625a:	ae2c0c13          	addi	s8,s8,-1310 # 80021d38 <disk+0x128>
    8000625e:	a8b5                	j	800062da <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006260:	00fb06b3          	add	a3,s6,a5
    80006264:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006268:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000626a:	0207c563          	bltz	a5,80006294 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000626e:	2485                	addiw	s1,s1,1
    80006270:	0711                	addi	a4,a4,4
    80006272:	1f548a63          	beq	s1,s5,80006466 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006276:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006278:	0001c697          	auipc	a3,0x1c
    8000627c:	99868693          	addi	a3,a3,-1640 # 80021c10 <disk>
    80006280:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006282:	0186c583          	lbu	a1,24(a3)
    80006286:	fde9                	bnez	a1,80006260 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006288:	2785                	addiw	a5,a5,1
    8000628a:	0685                	addi	a3,a3,1
    8000628c:	ff779be3          	bne	a5,s7,80006282 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006290:	57fd                	li	a5,-1
    80006292:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006294:	02905a63          	blez	s1,800062c8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006298:	f9042503          	lw	a0,-112(s0)
    8000629c:	00000097          	auipc	ra,0x0
    800062a0:	cfa080e7          	jalr	-774(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    800062a4:	4785                	li	a5,1
    800062a6:	0297d163          	bge	a5,s1,800062c8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800062aa:	f9442503          	lw	a0,-108(s0)
    800062ae:	00000097          	auipc	ra,0x0
    800062b2:	ce8080e7          	jalr	-792(ra) # 80005f96 <free_desc>
      for(int j = 0; j < i; j++)
    800062b6:	4789                	li	a5,2
    800062b8:	0097d863          	bge	a5,s1,800062c8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800062bc:	f9842503          	lw	a0,-104(s0)
    800062c0:	00000097          	auipc	ra,0x0
    800062c4:	cd6080e7          	jalr	-810(ra) # 80005f96 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062c8:	85e2                	mv	a1,s8
    800062ca:	0001c517          	auipc	a0,0x1c
    800062ce:	95e50513          	addi	a0,a0,-1698 # 80021c28 <disk+0x18>
    800062d2:	ffffc097          	auipc	ra,0xffffc
    800062d6:	d98080e7          	jalr	-616(ra) # 8000206a <sleep>
  for(int i = 0; i < 3; i++){
    800062da:	f9040713          	addi	a4,s0,-112
    800062de:	84ce                	mv	s1,s3
    800062e0:	bf59                	j	80006276 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800062e2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800062e6:	00479693          	slli	a3,a5,0x4
    800062ea:	0001c797          	auipc	a5,0x1c
    800062ee:	92678793          	addi	a5,a5,-1754 # 80021c10 <disk>
    800062f2:	97b6                	add	a5,a5,a3
    800062f4:	4685                	li	a3,1
    800062f6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062f8:	0001c597          	auipc	a1,0x1c
    800062fc:	91858593          	addi	a1,a1,-1768 # 80021c10 <disk>
    80006300:	00a60793          	addi	a5,a2,10
    80006304:	0792                	slli	a5,a5,0x4
    80006306:	97ae                	add	a5,a5,a1
    80006308:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000630c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006310:	f6070693          	addi	a3,a4,-160
    80006314:	619c                	ld	a5,0(a1)
    80006316:	97b6                	add	a5,a5,a3
    80006318:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000631a:	6188                	ld	a0,0(a1)
    8000631c:	96aa                	add	a3,a3,a0
    8000631e:	47c1                	li	a5,16
    80006320:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006322:	4785                	li	a5,1
    80006324:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006328:	f9442783          	lw	a5,-108(s0)
    8000632c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006330:	0792                	slli	a5,a5,0x4
    80006332:	953e                	add	a0,a0,a5
    80006334:	05890693          	addi	a3,s2,88
    80006338:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000633a:	6188                	ld	a0,0(a1)
    8000633c:	97aa                	add	a5,a5,a0
    8000633e:	40000693          	li	a3,1024
    80006342:	c794                	sw	a3,8(a5)
  if(write)
    80006344:	100d0d63          	beqz	s10,8000645e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006348:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000634c:	00c7d683          	lhu	a3,12(a5)
    80006350:	0016e693          	ori	a3,a3,1
    80006354:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006358:	f9842583          	lw	a1,-104(s0)
    8000635c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006360:	0001c697          	auipc	a3,0x1c
    80006364:	8b068693          	addi	a3,a3,-1872 # 80021c10 <disk>
    80006368:	00260793          	addi	a5,a2,2
    8000636c:	0792                	slli	a5,a5,0x4
    8000636e:	97b6                	add	a5,a5,a3
    80006370:	587d                	li	a6,-1
    80006372:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006376:	0592                	slli	a1,a1,0x4
    80006378:	952e                	add	a0,a0,a1
    8000637a:	f9070713          	addi	a4,a4,-112
    8000637e:	9736                	add	a4,a4,a3
    80006380:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006382:	6298                	ld	a4,0(a3)
    80006384:	972e                	add	a4,a4,a1
    80006386:	4585                	li	a1,1
    80006388:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000638a:	4509                	li	a0,2
    8000638c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006390:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006394:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006398:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000639c:	6698                	ld	a4,8(a3)
    8000639e:	00275783          	lhu	a5,2(a4)
    800063a2:	8b9d                	andi	a5,a5,7
    800063a4:	0786                	slli	a5,a5,0x1
    800063a6:	97ba                	add	a5,a5,a4
    800063a8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800063ac:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800063b0:	6698                	ld	a4,8(a3)
    800063b2:	00275783          	lhu	a5,2(a4)
    800063b6:	2785                	addiw	a5,a5,1
    800063b8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063bc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063c0:	100017b7          	lui	a5,0x10001
    800063c4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063c8:	00492703          	lw	a4,4(s2)
    800063cc:	4785                	li	a5,1
    800063ce:	02f71163          	bne	a4,a5,800063f0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800063d2:	0001c997          	auipc	s3,0x1c
    800063d6:	96698993          	addi	s3,s3,-1690 # 80021d38 <disk+0x128>
  while(b->disk == 1) {
    800063da:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800063dc:	85ce                	mv	a1,s3
    800063de:	854a                	mv	a0,s2
    800063e0:	ffffc097          	auipc	ra,0xffffc
    800063e4:	c8a080e7          	jalr	-886(ra) # 8000206a <sleep>
  while(b->disk == 1) {
    800063e8:	00492783          	lw	a5,4(s2)
    800063ec:	fe9788e3          	beq	a5,s1,800063dc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800063f0:	f9042903          	lw	s2,-112(s0)
    800063f4:	00290793          	addi	a5,s2,2
    800063f8:	00479713          	slli	a4,a5,0x4
    800063fc:	0001c797          	auipc	a5,0x1c
    80006400:	81478793          	addi	a5,a5,-2028 # 80021c10 <disk>
    80006404:	97ba                	add	a5,a5,a4
    80006406:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000640a:	0001c997          	auipc	s3,0x1c
    8000640e:	80698993          	addi	s3,s3,-2042 # 80021c10 <disk>
    80006412:	00491713          	slli	a4,s2,0x4
    80006416:	0009b783          	ld	a5,0(s3)
    8000641a:	97ba                	add	a5,a5,a4
    8000641c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006420:	854a                	mv	a0,s2
    80006422:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006426:	00000097          	auipc	ra,0x0
    8000642a:	b70080e7          	jalr	-1168(ra) # 80005f96 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000642e:	8885                	andi	s1,s1,1
    80006430:	f0ed                	bnez	s1,80006412 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006432:	0001c517          	auipc	a0,0x1c
    80006436:	90650513          	addi	a0,a0,-1786 # 80021d38 <disk+0x128>
    8000643a:	ffffb097          	auipc	ra,0xffffb
    8000643e:	864080e7          	jalr	-1948(ra) # 80000c9e <release>
}
    80006442:	70a6                	ld	ra,104(sp)
    80006444:	7406                	ld	s0,96(sp)
    80006446:	64e6                	ld	s1,88(sp)
    80006448:	6946                	ld	s2,80(sp)
    8000644a:	69a6                	ld	s3,72(sp)
    8000644c:	6a06                	ld	s4,64(sp)
    8000644e:	7ae2                	ld	s5,56(sp)
    80006450:	7b42                	ld	s6,48(sp)
    80006452:	7ba2                	ld	s7,40(sp)
    80006454:	7c02                	ld	s8,32(sp)
    80006456:	6ce2                	ld	s9,24(sp)
    80006458:	6d42                	ld	s10,16(sp)
    8000645a:	6165                	addi	sp,sp,112
    8000645c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000645e:	4689                	li	a3,2
    80006460:	00d79623          	sh	a3,12(a5)
    80006464:	b5e5                	j	8000634c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006466:	f9042603          	lw	a2,-112(s0)
    8000646a:	00a60713          	addi	a4,a2,10
    8000646e:	0712                	slli	a4,a4,0x4
    80006470:	0001b517          	auipc	a0,0x1b
    80006474:	7a850513          	addi	a0,a0,1960 # 80021c18 <disk+0x8>
    80006478:	953a                	add	a0,a0,a4
  if(write)
    8000647a:	e60d14e3          	bnez	s10,800062e2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000647e:	00a60793          	addi	a5,a2,10
    80006482:	00479693          	slli	a3,a5,0x4
    80006486:	0001b797          	auipc	a5,0x1b
    8000648a:	78a78793          	addi	a5,a5,1930 # 80021c10 <disk>
    8000648e:	97b6                	add	a5,a5,a3
    80006490:	0007a423          	sw	zero,8(a5)
    80006494:	b595                	j	800062f8 <virtio_disk_rw+0xf0>

0000000080006496 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006496:	1101                	addi	sp,sp,-32
    80006498:	ec06                	sd	ra,24(sp)
    8000649a:	e822                	sd	s0,16(sp)
    8000649c:	e426                	sd	s1,8(sp)
    8000649e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064a0:	0001b497          	auipc	s1,0x1b
    800064a4:	77048493          	addi	s1,s1,1904 # 80021c10 <disk>
    800064a8:	0001c517          	auipc	a0,0x1c
    800064ac:	89050513          	addi	a0,a0,-1904 # 80021d38 <disk+0x128>
    800064b0:	ffffa097          	auipc	ra,0xffffa
    800064b4:	73a080e7          	jalr	1850(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064b8:	10001737          	lui	a4,0x10001
    800064bc:	533c                	lw	a5,96(a4)
    800064be:	8b8d                	andi	a5,a5,3
    800064c0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064c2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064c6:	689c                	ld	a5,16(s1)
    800064c8:	0204d703          	lhu	a4,32(s1)
    800064cc:	0027d783          	lhu	a5,2(a5)
    800064d0:	04f70863          	beq	a4,a5,80006520 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064d4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064d8:	6898                	ld	a4,16(s1)
    800064da:	0204d783          	lhu	a5,32(s1)
    800064de:	8b9d                	andi	a5,a5,7
    800064e0:	078e                	slli	a5,a5,0x3
    800064e2:	97ba                	add	a5,a5,a4
    800064e4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064e6:	00278713          	addi	a4,a5,2
    800064ea:	0712                	slli	a4,a4,0x4
    800064ec:	9726                	add	a4,a4,s1
    800064ee:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064f2:	e721                	bnez	a4,8000653a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064f4:	0789                	addi	a5,a5,2
    800064f6:	0792                	slli	a5,a5,0x4
    800064f8:	97a6                	add	a5,a5,s1
    800064fa:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064fc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006500:	ffffc097          	auipc	ra,0xffffc
    80006504:	bce080e7          	jalr	-1074(ra) # 800020ce <wakeup>

    disk.used_idx += 1;
    80006508:	0204d783          	lhu	a5,32(s1)
    8000650c:	2785                	addiw	a5,a5,1
    8000650e:	17c2                	slli	a5,a5,0x30
    80006510:	93c1                	srli	a5,a5,0x30
    80006512:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006516:	6898                	ld	a4,16(s1)
    80006518:	00275703          	lhu	a4,2(a4)
    8000651c:	faf71ce3          	bne	a4,a5,800064d4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006520:	0001c517          	auipc	a0,0x1c
    80006524:	81850513          	addi	a0,a0,-2024 # 80021d38 <disk+0x128>
    80006528:	ffffa097          	auipc	ra,0xffffa
    8000652c:	776080e7          	jalr	1910(ra) # 80000c9e <release>
}
    80006530:	60e2                	ld	ra,24(sp)
    80006532:	6442                	ld	s0,16(sp)
    80006534:	64a2                	ld	s1,8(sp)
    80006536:	6105                	addi	sp,sp,32
    80006538:	8082                	ret
      panic("virtio_disk_intr status");
    8000653a:	00002517          	auipc	a0,0x2
    8000653e:	2fe50513          	addi	a0,a0,766 # 80008838 <syscalls+0x3e8>
    80006542:	ffffa097          	auipc	ra,0xffffa
    80006546:	002080e7          	jalr	2(ra) # 80000544 <panic>
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
