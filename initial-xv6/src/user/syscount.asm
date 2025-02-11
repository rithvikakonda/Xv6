
user/_syscount:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "user/user.h"
#include "kernel/syscall.h"

int
main(int argc, char *argv[])
{
   0:	7111                	addi	sp,sp,-256
   2:	fd86                	sd	ra,248(sp)
   4:	f9a2                	sd	s0,240(sp)
   6:	0200                	addi	s0,sp,256
    if (argc < 3) {
   8:	4789                	li	a5,2
   a:	02a7c363          	blt	a5,a0,30 <main+0x30>
   e:	f5a6                	sd	s1,232(sp)
  10:	f1ca                	sd	s2,224(sp)
  12:	edce                	sd	s3,216(sp)
        fprintf(2, "Usage: syscount <mask> <command> [args...]\n");
  14:	00001597          	auipc	a1,0x1
  18:	93c58593          	addi	a1,a1,-1732 # 950 <malloc+0x100>
  1c:	4509                	li	a0,2
  1e:	00000097          	auipc	ra,0x0
  22:	74c080e7          	jalr	1868(ra) # 76a <fprintf>
        exit(1);
  26:	4505                	li	a0,1
  28:	00000097          	auipc	ra,0x0
  2c:	3e0080e7          	jalr	992(ra) # 408 <exit>
  30:	f5a6                	sd	s1,232(sp)
  32:	f1ca                	sd	s2,224(sp)
  34:	edce                	sd	s3,216(sp)
  36:	892e                	mv	s2,a1
    }
    int mask = atoi(argv[1]);
  38:	6588                	ld	a0,8(a1)
  3a:	00000097          	auipc	ra,0x0
  3e:	2d4080e7          	jalr	724(ra) # 30e <atoi>
  42:	84aa                	mv	s1,a0

    int pid = fork();
  44:	00000097          	auipc	ra,0x0
  48:	3bc080e7          	jalr	956(ra) # 400 <fork>
  4c:	89aa                	mv	s3,a0
    if (pid < 0) {
  4e:	02054963          	bltz	a0,80 <main+0x80>
        fprintf(2, "fork failed\n");
        exit(1);
    }

    if (pid == 0) { // Child process
  52:	e529                	bnez	a0,9c <main+0x9c>
        exec(argv[2], &argv[2]);
  54:	01090593          	addi	a1,s2,16
  58:	01093503          	ld	a0,16(s2)
  5c:	00000097          	auipc	ra,0x0
  60:	3e4080e7          	jalr	996(ra) # 440 <exec>
        fprintf(2, "exec failed\n");
  64:	00001597          	auipc	a1,0x1
  68:	92c58593          	addi	a1,a1,-1748 # 990 <malloc+0x140>
  6c:	4509                	li	a0,2
  6e:	00000097          	auipc	ra,0x0
  72:	6fc080e7          	jalr	1788(ra) # 76a <fprintf>
        exit(1);
  76:	4505                	li	a0,1
  78:	00000097          	auipc	ra,0x0
  7c:	390080e7          	jalr	912(ra) # 408 <exit>
        fprintf(2, "fork failed\n");
  80:	00001597          	auipc	a1,0x1
  84:	90058593          	addi	a1,a1,-1792 # 980 <malloc+0x130>
  88:	4509                	li	a0,2
  8a:	00000097          	auipc	ra,0x0
  8e:	6e0080e7          	jalr	1760(ra) # 76a <fprintf>
        exit(1);
  92:	4505                	li	a0,1
  94:	00000097          	auipc	ra,0x0
  98:	374080e7          	jalr	884(ra) # 408 <exit>
    }

   
    wait(0);
  9c:	4501                	li	a0,0
  9e:	00000097          	auipc	ra,0x0
  a2:	372080e7          	jalr	882(ra) # 410 <wait>

    uint64 count = getSysCount(mask);
  a6:	8526                	mv	a0,s1
  a8:	00000097          	auipc	ra,0x0
  ac:	408080e7          	jalr	1032(ra) # 4b0 <getSysCount>
    int syscall_num = 0;
    while (mask > 1) {
  b0:	4785                	li	a5,1
  b2:	0697d463          	bge	a5,s1,11a <main+0x11a>
    int syscall_num = 0;
  b6:	4601                	li	a2,0
        syscall_num++;
  b8:	2605                	addiw	a2,a2,1
        mask >>= 1;
  ba:	4014d49b          	sraiw	s1,s1,0x1
    while (mask > 1) {
  be:	fe97cde3          	blt	a5,s1,b8 <main+0xb8>
    }

    char *syscall_names[] = {
  c2:	00001797          	auipc	a5,0x1
  c6:	9f678793          	addi	a5,a5,-1546 # ab8 <malloc+0x268>
  ca:	f0040713          	addi	a4,s0,-256
  ce:	00001e97          	auipc	t4,0x1
  d2:	ab2e8e93          	addi	t4,t4,-1358 # b80 <malloc+0x330>
  d6:	0007be03          	ld	t3,0(a5)
  da:	0087b303          	ld	t1,8(a5)
  de:	0107b883          	ld	a7,16(a5)
  e2:	0187b803          	ld	a6,24(a5)
  e6:	738c                	ld	a1,32(a5)
  e8:	01c73023          	sd	t3,0(a4)
  ec:	00673423          	sd	t1,8(a4)
  f0:	01173823          	sd	a7,16(a4)
  f4:	01073c23          	sd	a6,24(a4)
  f8:	f30c                	sd	a1,32(a4)
  fa:	02878793          	addi	a5,a5,40
  fe:	02870713          	addi	a4,a4,40
 102:	fdd79ae3          	bne	a5,t4,d6 <main+0xd6>
 106:	639c                	ld	a5,0(a5)
 108:	e31c                	sd	a5,0(a4)
        "fork", "exit", "wait", "pipe", "read", "kill", "exec", "fstat", "chdir", "dup",
        "getpid", "sbrk", "sleep", "uptime", "open", "write", "mknod", "unlink", "link", "mkdir",
        "close", "waitx", "getSysCount" ,"sigalarm" ,"sigreturn","settickets" // Add new syscalls here
    };

    if (syscall_num < 32) { // Assume there are 24 syscalls for now
 10a:	47fd                	li	a5,31
 10c:	04c7d863          	bge	a5,a2,15c <main+0x15c>
        printf("PID %d called %s %d times.\n", pid, syscall_names[syscall_num-1], count);
    }

    exit(0);
 110:	4501                	li	a0,0
 112:	00000097          	auipc	ra,0x0
 116:	2f6080e7          	jalr	758(ra) # 408 <exit>
    char *syscall_names[] = {
 11a:	00001797          	auipc	a5,0x1
 11e:	99e78793          	addi	a5,a5,-1634 # ab8 <malloc+0x268>
 122:	f0040713          	addi	a4,s0,-256
 126:	00001317          	auipc	t1,0x1
 12a:	a5a30313          	addi	t1,t1,-1446 # b80 <malloc+0x330>
 12e:	0007b883          	ld	a7,0(a5)
 132:	0087b803          	ld	a6,8(a5)
 136:	6b8c                	ld	a1,16(a5)
 138:	6f90                	ld	a2,24(a5)
 13a:	7394                	ld	a3,32(a5)
 13c:	01173023          	sd	a7,0(a4)
 140:	01073423          	sd	a6,8(a4)
 144:	eb0c                	sd	a1,16(a4)
 146:	ef10                	sd	a2,24(a4)
 148:	f314                	sd	a3,32(a4)
 14a:	02878793          	addi	a5,a5,40
 14e:	02870713          	addi	a4,a4,40
 152:	fc679ee3          	bne	a5,t1,12e <main+0x12e>
 156:	639c                	ld	a5,0(a5)
 158:	e31c                	sd	a5,0(a4)
    int syscall_num = 0;
 15a:	4601                	li	a2,0
        printf("PID %d called %s %d times.\n", pid, syscall_names[syscall_num-1], count);
 15c:	fff6079b          	addiw	a5,a2,-1
 160:	078e                	slli	a5,a5,0x3
 162:	fd078793          	addi	a5,a5,-48
 166:	97a2                	add	a5,a5,s0
 168:	86aa                	mv	a3,a0
 16a:	f307b603          	ld	a2,-208(a5)
 16e:	85ce                	mv	a1,s3
 170:	00001517          	auipc	a0,0x1
 174:	83050513          	addi	a0,a0,-2000 # 9a0 <malloc+0x150>
 178:	00000097          	auipc	ra,0x0
 17c:	620080e7          	jalr	1568(ra) # 798 <printf>
 180:	bf41                	j	110 <main+0x110>

0000000000000182 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 182:	1141                	addi	sp,sp,-16
 184:	e406                	sd	ra,8(sp)
 186:	e022                	sd	s0,0(sp)
 188:	0800                	addi	s0,sp,16
  extern int main();
  main();
 18a:	00000097          	auipc	ra,0x0
 18e:	e76080e7          	jalr	-394(ra) # 0 <main>
  exit(0);
 192:	4501                	li	a0,0
 194:	00000097          	auipc	ra,0x0
 198:	274080e7          	jalr	628(ra) # 408 <exit>

000000000000019c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 19c:	1141                	addi	sp,sp,-16
 19e:	e422                	sd	s0,8(sp)
 1a0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1a2:	87aa                	mv	a5,a0
 1a4:	0585                	addi	a1,a1,1
 1a6:	0785                	addi	a5,a5,1
 1a8:	fff5c703          	lbu	a4,-1(a1)
 1ac:	fee78fa3          	sb	a4,-1(a5)
 1b0:	fb75                	bnez	a4,1a4 <strcpy+0x8>
    ;
  return os;
}
 1b2:	6422                	ld	s0,8(sp)
 1b4:	0141                	addi	sp,sp,16
 1b6:	8082                	ret

00000000000001b8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1b8:	1141                	addi	sp,sp,-16
 1ba:	e422                	sd	s0,8(sp)
 1bc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1be:	00054783          	lbu	a5,0(a0)
 1c2:	cb91                	beqz	a5,1d6 <strcmp+0x1e>
 1c4:	0005c703          	lbu	a4,0(a1)
 1c8:	00f71763          	bne	a4,a5,1d6 <strcmp+0x1e>
    p++, q++;
 1cc:	0505                	addi	a0,a0,1
 1ce:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1d0:	00054783          	lbu	a5,0(a0)
 1d4:	fbe5                	bnez	a5,1c4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1d6:	0005c503          	lbu	a0,0(a1)
}
 1da:	40a7853b          	subw	a0,a5,a0
 1de:	6422                	ld	s0,8(sp)
 1e0:	0141                	addi	sp,sp,16
 1e2:	8082                	ret

00000000000001e4 <strlen>:

uint
strlen(const char *s)
{
 1e4:	1141                	addi	sp,sp,-16
 1e6:	e422                	sd	s0,8(sp)
 1e8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1ea:	00054783          	lbu	a5,0(a0)
 1ee:	cf91                	beqz	a5,20a <strlen+0x26>
 1f0:	0505                	addi	a0,a0,1
 1f2:	87aa                	mv	a5,a0
 1f4:	86be                	mv	a3,a5
 1f6:	0785                	addi	a5,a5,1
 1f8:	fff7c703          	lbu	a4,-1(a5)
 1fc:	ff65                	bnez	a4,1f4 <strlen+0x10>
 1fe:	40a6853b          	subw	a0,a3,a0
 202:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 204:	6422                	ld	s0,8(sp)
 206:	0141                	addi	sp,sp,16
 208:	8082                	ret
  for(n = 0; s[n]; n++)
 20a:	4501                	li	a0,0
 20c:	bfe5                	j	204 <strlen+0x20>

000000000000020e <memset>:

void*
memset(void *dst, int c, uint n)
{
 20e:	1141                	addi	sp,sp,-16
 210:	e422                	sd	s0,8(sp)
 212:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 214:	ca19                	beqz	a2,22a <memset+0x1c>
 216:	87aa                	mv	a5,a0
 218:	1602                	slli	a2,a2,0x20
 21a:	9201                	srli	a2,a2,0x20
 21c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 220:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 224:	0785                	addi	a5,a5,1
 226:	fee79de3          	bne	a5,a4,220 <memset+0x12>
  }
  return dst;
}
 22a:	6422                	ld	s0,8(sp)
 22c:	0141                	addi	sp,sp,16
 22e:	8082                	ret

0000000000000230 <strchr>:

char*
strchr(const char *s, char c)
{
 230:	1141                	addi	sp,sp,-16
 232:	e422                	sd	s0,8(sp)
 234:	0800                	addi	s0,sp,16
  for(; *s; s++)
 236:	00054783          	lbu	a5,0(a0)
 23a:	cb99                	beqz	a5,250 <strchr+0x20>
    if(*s == c)
 23c:	00f58763          	beq	a1,a5,24a <strchr+0x1a>
  for(; *s; s++)
 240:	0505                	addi	a0,a0,1
 242:	00054783          	lbu	a5,0(a0)
 246:	fbfd                	bnez	a5,23c <strchr+0xc>
      return (char*)s;
  return 0;
 248:	4501                	li	a0,0
}
 24a:	6422                	ld	s0,8(sp)
 24c:	0141                	addi	sp,sp,16
 24e:	8082                	ret
  return 0;
 250:	4501                	li	a0,0
 252:	bfe5                	j	24a <strchr+0x1a>

0000000000000254 <gets>:

char*
gets(char *buf, int max)
{
 254:	711d                	addi	sp,sp,-96
 256:	ec86                	sd	ra,88(sp)
 258:	e8a2                	sd	s0,80(sp)
 25a:	e4a6                	sd	s1,72(sp)
 25c:	e0ca                	sd	s2,64(sp)
 25e:	fc4e                	sd	s3,56(sp)
 260:	f852                	sd	s4,48(sp)
 262:	f456                	sd	s5,40(sp)
 264:	f05a                	sd	s6,32(sp)
 266:	ec5e                	sd	s7,24(sp)
 268:	1080                	addi	s0,sp,96
 26a:	8baa                	mv	s7,a0
 26c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 26e:	892a                	mv	s2,a0
 270:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 272:	4aa9                	li	s5,10
 274:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 276:	89a6                	mv	s3,s1
 278:	2485                	addiw	s1,s1,1
 27a:	0344d863          	bge	s1,s4,2aa <gets+0x56>
    cc = read(0, &c, 1);
 27e:	4605                	li	a2,1
 280:	faf40593          	addi	a1,s0,-81
 284:	4501                	li	a0,0
 286:	00000097          	auipc	ra,0x0
 28a:	19a080e7          	jalr	410(ra) # 420 <read>
    if(cc < 1)
 28e:	00a05e63          	blez	a0,2aa <gets+0x56>
    buf[i++] = c;
 292:	faf44783          	lbu	a5,-81(s0)
 296:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 29a:	01578763          	beq	a5,s5,2a8 <gets+0x54>
 29e:	0905                	addi	s2,s2,1
 2a0:	fd679be3          	bne	a5,s6,276 <gets+0x22>
    buf[i++] = c;
 2a4:	89a6                	mv	s3,s1
 2a6:	a011                	j	2aa <gets+0x56>
 2a8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2aa:	99de                	add	s3,s3,s7
 2ac:	00098023          	sb	zero,0(s3)
  return buf;
}
 2b0:	855e                	mv	a0,s7
 2b2:	60e6                	ld	ra,88(sp)
 2b4:	6446                	ld	s0,80(sp)
 2b6:	64a6                	ld	s1,72(sp)
 2b8:	6906                	ld	s2,64(sp)
 2ba:	79e2                	ld	s3,56(sp)
 2bc:	7a42                	ld	s4,48(sp)
 2be:	7aa2                	ld	s5,40(sp)
 2c0:	7b02                	ld	s6,32(sp)
 2c2:	6be2                	ld	s7,24(sp)
 2c4:	6125                	addi	sp,sp,96
 2c6:	8082                	ret

00000000000002c8 <stat>:

int
stat(const char *n, struct stat *st)
{
 2c8:	1101                	addi	sp,sp,-32
 2ca:	ec06                	sd	ra,24(sp)
 2cc:	e822                	sd	s0,16(sp)
 2ce:	e04a                	sd	s2,0(sp)
 2d0:	1000                	addi	s0,sp,32
 2d2:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2d4:	4581                	li	a1,0
 2d6:	00000097          	auipc	ra,0x0
 2da:	172080e7          	jalr	370(ra) # 448 <open>
  if(fd < 0)
 2de:	02054663          	bltz	a0,30a <stat+0x42>
 2e2:	e426                	sd	s1,8(sp)
 2e4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2e6:	85ca                	mv	a1,s2
 2e8:	00000097          	auipc	ra,0x0
 2ec:	178080e7          	jalr	376(ra) # 460 <fstat>
 2f0:	892a                	mv	s2,a0
  close(fd);
 2f2:	8526                	mv	a0,s1
 2f4:	00000097          	auipc	ra,0x0
 2f8:	13c080e7          	jalr	316(ra) # 430 <close>
  return r;
 2fc:	64a2                	ld	s1,8(sp)
}
 2fe:	854a                	mv	a0,s2
 300:	60e2                	ld	ra,24(sp)
 302:	6442                	ld	s0,16(sp)
 304:	6902                	ld	s2,0(sp)
 306:	6105                	addi	sp,sp,32
 308:	8082                	ret
    return -1;
 30a:	597d                	li	s2,-1
 30c:	bfcd                	j	2fe <stat+0x36>

000000000000030e <atoi>:

int
atoi(const char *s)
{
 30e:	1141                	addi	sp,sp,-16
 310:	e422                	sd	s0,8(sp)
 312:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 314:	00054683          	lbu	a3,0(a0)
 318:	fd06879b          	addiw	a5,a3,-48
 31c:	0ff7f793          	zext.b	a5,a5
 320:	4625                	li	a2,9
 322:	02f66863          	bltu	a2,a5,352 <atoi+0x44>
 326:	872a                	mv	a4,a0
  n = 0;
 328:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 32a:	0705                	addi	a4,a4,1
 32c:	0025179b          	slliw	a5,a0,0x2
 330:	9fa9                	addw	a5,a5,a0
 332:	0017979b          	slliw	a5,a5,0x1
 336:	9fb5                	addw	a5,a5,a3
 338:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 33c:	00074683          	lbu	a3,0(a4)
 340:	fd06879b          	addiw	a5,a3,-48
 344:	0ff7f793          	zext.b	a5,a5
 348:	fef671e3          	bgeu	a2,a5,32a <atoi+0x1c>
  return n;
}
 34c:	6422                	ld	s0,8(sp)
 34e:	0141                	addi	sp,sp,16
 350:	8082                	ret
  n = 0;
 352:	4501                	li	a0,0
 354:	bfe5                	j	34c <atoi+0x3e>

0000000000000356 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 356:	1141                	addi	sp,sp,-16
 358:	e422                	sd	s0,8(sp)
 35a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 35c:	02b57463          	bgeu	a0,a1,384 <memmove+0x2e>
    while(n-- > 0)
 360:	00c05f63          	blez	a2,37e <memmove+0x28>
 364:	1602                	slli	a2,a2,0x20
 366:	9201                	srli	a2,a2,0x20
 368:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 36c:	872a                	mv	a4,a0
      *dst++ = *src++;
 36e:	0585                	addi	a1,a1,1
 370:	0705                	addi	a4,a4,1
 372:	fff5c683          	lbu	a3,-1(a1)
 376:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 37a:	fef71ae3          	bne	a4,a5,36e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 37e:	6422                	ld	s0,8(sp)
 380:	0141                	addi	sp,sp,16
 382:	8082                	ret
    dst += n;
 384:	00c50733          	add	a4,a0,a2
    src += n;
 388:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 38a:	fec05ae3          	blez	a2,37e <memmove+0x28>
 38e:	fff6079b          	addiw	a5,a2,-1
 392:	1782                	slli	a5,a5,0x20
 394:	9381                	srli	a5,a5,0x20
 396:	fff7c793          	not	a5,a5
 39a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 39c:	15fd                	addi	a1,a1,-1
 39e:	177d                	addi	a4,a4,-1
 3a0:	0005c683          	lbu	a3,0(a1)
 3a4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3a8:	fee79ae3          	bne	a5,a4,39c <memmove+0x46>
 3ac:	bfc9                	j	37e <memmove+0x28>

00000000000003ae <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3ae:	1141                	addi	sp,sp,-16
 3b0:	e422                	sd	s0,8(sp)
 3b2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3b4:	ca05                	beqz	a2,3e4 <memcmp+0x36>
 3b6:	fff6069b          	addiw	a3,a2,-1
 3ba:	1682                	slli	a3,a3,0x20
 3bc:	9281                	srli	a3,a3,0x20
 3be:	0685                	addi	a3,a3,1
 3c0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3c2:	00054783          	lbu	a5,0(a0)
 3c6:	0005c703          	lbu	a4,0(a1)
 3ca:	00e79863          	bne	a5,a4,3da <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ce:	0505                	addi	a0,a0,1
    p2++;
 3d0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3d2:	fed518e3          	bne	a0,a3,3c2 <memcmp+0x14>
  }
  return 0;
 3d6:	4501                	li	a0,0
 3d8:	a019                	j	3de <memcmp+0x30>
      return *p1 - *p2;
 3da:	40e7853b          	subw	a0,a5,a4
}
 3de:	6422                	ld	s0,8(sp)
 3e0:	0141                	addi	sp,sp,16
 3e2:	8082                	ret
  return 0;
 3e4:	4501                	li	a0,0
 3e6:	bfe5                	j	3de <memcmp+0x30>

00000000000003e8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3e8:	1141                	addi	sp,sp,-16
 3ea:	e406                	sd	ra,8(sp)
 3ec:	e022                	sd	s0,0(sp)
 3ee:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3f0:	00000097          	auipc	ra,0x0
 3f4:	f66080e7          	jalr	-154(ra) # 356 <memmove>
}
 3f8:	60a2                	ld	ra,8(sp)
 3fa:	6402                	ld	s0,0(sp)
 3fc:	0141                	addi	sp,sp,16
 3fe:	8082                	ret

0000000000000400 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 400:	4885                	li	a7,1
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <exit>:
.global exit
exit:
 li a7, SYS_exit
 408:	4889                	li	a7,2
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <wait>:
.global wait
wait:
 li a7, SYS_wait
 410:	488d                	li	a7,3
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 418:	4891                	li	a7,4
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <read>:
.global read
read:
 li a7, SYS_read
 420:	4895                	li	a7,5
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <write>:
.global write
write:
 li a7, SYS_write
 428:	48c1                	li	a7,16
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <close>:
.global close
close:
 li a7, SYS_close
 430:	48d5                	li	a7,21
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <kill>:
.global kill
kill:
 li a7, SYS_kill
 438:	4899                	li	a7,6
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <exec>:
.global exec
exec:
 li a7, SYS_exec
 440:	489d                	li	a7,7
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <open>:
.global open
open:
 li a7, SYS_open
 448:	48bd                	li	a7,15
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 450:	48c5                	li	a7,17
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 458:	48c9                	li	a7,18
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 460:	48a1                	li	a7,8
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <link>:
.global link
link:
 li a7, SYS_link
 468:	48cd                	li	a7,19
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 470:	48d1                	li	a7,20
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 478:	48a5                	li	a7,9
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <dup>:
.global dup
dup:
 li a7, SYS_dup
 480:	48a9                	li	a7,10
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 488:	48ad                	li	a7,11
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 490:	48b1                	li	a7,12
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 498:	48b5                	li	a7,13
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4a0:	48b9                	li	a7,14
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 4a8:	48d9                	li	a7,22
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 4b0:	48dd                	li	a7,23
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 4b8:	48e1                	li	a7,24
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 4c0:	48e5                	li	a7,25
 ecall
 4c2:	00000073          	ecall
 ret
 4c6:	8082                	ret

00000000000004c8 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 4c8:	48e9                	li	a7,26
 ecall
 4ca:	00000073          	ecall
 ret
 4ce:	8082                	ret

00000000000004d0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4d0:	1101                	addi	sp,sp,-32
 4d2:	ec06                	sd	ra,24(sp)
 4d4:	e822                	sd	s0,16(sp)
 4d6:	1000                	addi	s0,sp,32
 4d8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4dc:	4605                	li	a2,1
 4de:	fef40593          	addi	a1,s0,-17
 4e2:	00000097          	auipc	ra,0x0
 4e6:	f46080e7          	jalr	-186(ra) # 428 <write>
}
 4ea:	60e2                	ld	ra,24(sp)
 4ec:	6442                	ld	s0,16(sp)
 4ee:	6105                	addi	sp,sp,32
 4f0:	8082                	ret

00000000000004f2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4f2:	7139                	addi	sp,sp,-64
 4f4:	fc06                	sd	ra,56(sp)
 4f6:	f822                	sd	s0,48(sp)
 4f8:	f426                	sd	s1,40(sp)
 4fa:	0080                	addi	s0,sp,64
 4fc:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4fe:	c299                	beqz	a3,504 <printint+0x12>
 500:	0805cb63          	bltz	a1,596 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 504:	2581                	sext.w	a1,a1
  neg = 0;
 506:	4881                	li	a7,0
 508:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 50c:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 50e:	2601                	sext.w	a2,a2
 510:	00000517          	auipc	a0,0x0
 514:	6d050513          	addi	a0,a0,1744 # be0 <digits>
 518:	883a                	mv	a6,a4
 51a:	2705                	addiw	a4,a4,1
 51c:	02c5f7bb          	remuw	a5,a1,a2
 520:	1782                	slli	a5,a5,0x20
 522:	9381                	srli	a5,a5,0x20
 524:	97aa                	add	a5,a5,a0
 526:	0007c783          	lbu	a5,0(a5)
 52a:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 52e:	0005879b          	sext.w	a5,a1
 532:	02c5d5bb          	divuw	a1,a1,a2
 536:	0685                	addi	a3,a3,1
 538:	fec7f0e3          	bgeu	a5,a2,518 <printint+0x26>
  if(neg)
 53c:	00088c63          	beqz	a7,554 <printint+0x62>
    buf[i++] = '-';
 540:	fd070793          	addi	a5,a4,-48
 544:	00878733          	add	a4,a5,s0
 548:	02d00793          	li	a5,45
 54c:	fef70823          	sb	a5,-16(a4)
 550:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 554:	02e05c63          	blez	a4,58c <printint+0x9a>
 558:	f04a                	sd	s2,32(sp)
 55a:	ec4e                	sd	s3,24(sp)
 55c:	fc040793          	addi	a5,s0,-64
 560:	00e78933          	add	s2,a5,a4
 564:	fff78993          	addi	s3,a5,-1
 568:	99ba                	add	s3,s3,a4
 56a:	377d                	addiw	a4,a4,-1
 56c:	1702                	slli	a4,a4,0x20
 56e:	9301                	srli	a4,a4,0x20
 570:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 574:	fff94583          	lbu	a1,-1(s2)
 578:	8526                	mv	a0,s1
 57a:	00000097          	auipc	ra,0x0
 57e:	f56080e7          	jalr	-170(ra) # 4d0 <putc>
  while(--i >= 0)
 582:	197d                	addi	s2,s2,-1
 584:	ff3918e3          	bne	s2,s3,574 <printint+0x82>
 588:	7902                	ld	s2,32(sp)
 58a:	69e2                	ld	s3,24(sp)
}
 58c:	70e2                	ld	ra,56(sp)
 58e:	7442                	ld	s0,48(sp)
 590:	74a2                	ld	s1,40(sp)
 592:	6121                	addi	sp,sp,64
 594:	8082                	ret
    x = -xx;
 596:	40b005bb          	negw	a1,a1
    neg = 1;
 59a:	4885                	li	a7,1
    x = -xx;
 59c:	b7b5                	j	508 <printint+0x16>

000000000000059e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 59e:	715d                	addi	sp,sp,-80
 5a0:	e486                	sd	ra,72(sp)
 5a2:	e0a2                	sd	s0,64(sp)
 5a4:	f84a                	sd	s2,48(sp)
 5a6:	0880                	addi	s0,sp,80
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5a8:	0005c903          	lbu	s2,0(a1)
 5ac:	1a090a63          	beqz	s2,760 <vprintf+0x1c2>
 5b0:	fc26                	sd	s1,56(sp)
 5b2:	f44e                	sd	s3,40(sp)
 5b4:	f052                	sd	s4,32(sp)
 5b6:	ec56                	sd	s5,24(sp)
 5b8:	e85a                	sd	s6,16(sp)
 5ba:	e45e                	sd	s7,8(sp)
 5bc:	8aaa                	mv	s5,a0
 5be:	8bb2                	mv	s7,a2
 5c0:	00158493          	addi	s1,a1,1
  state = 0;
 5c4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5c6:	02500a13          	li	s4,37
 5ca:	4b55                	li	s6,21
 5cc:	a839                	j	5ea <vprintf+0x4c>
        putc(fd, c);
 5ce:	85ca                	mv	a1,s2
 5d0:	8556                	mv	a0,s5
 5d2:	00000097          	auipc	ra,0x0
 5d6:	efe080e7          	jalr	-258(ra) # 4d0 <putc>
 5da:	a019                	j	5e0 <vprintf+0x42>
    } else if(state == '%'){
 5dc:	01498d63          	beq	s3,s4,5f6 <vprintf+0x58>
  for(i = 0; fmt[i]; i++){
 5e0:	0485                	addi	s1,s1,1
 5e2:	fff4c903          	lbu	s2,-1(s1)
 5e6:	16090763          	beqz	s2,754 <vprintf+0x1b6>
    if(state == 0){
 5ea:	fe0999e3          	bnez	s3,5dc <vprintf+0x3e>
      if(c == '%'){
 5ee:	ff4910e3          	bne	s2,s4,5ce <vprintf+0x30>
        state = '%';
 5f2:	89d2                	mv	s3,s4
 5f4:	b7f5                	j	5e0 <vprintf+0x42>
      if(c == 'd'){
 5f6:	13490463          	beq	s2,s4,71e <vprintf+0x180>
 5fa:	f9d9079b          	addiw	a5,s2,-99
 5fe:	0ff7f793          	zext.b	a5,a5
 602:	12fb6763          	bltu	s6,a5,730 <vprintf+0x192>
 606:	f9d9079b          	addiw	a5,s2,-99
 60a:	0ff7f713          	zext.b	a4,a5
 60e:	12eb6163          	bltu	s6,a4,730 <vprintf+0x192>
 612:	00271793          	slli	a5,a4,0x2
 616:	00000717          	auipc	a4,0x0
 61a:	57270713          	addi	a4,a4,1394 # b88 <malloc+0x338>
 61e:	97ba                	add	a5,a5,a4
 620:	439c                	lw	a5,0(a5)
 622:	97ba                	add	a5,a5,a4
 624:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 626:	008b8913          	addi	s2,s7,8
 62a:	4685                	li	a3,1
 62c:	4629                	li	a2,10
 62e:	000ba583          	lw	a1,0(s7)
 632:	8556                	mv	a0,s5
 634:	00000097          	auipc	ra,0x0
 638:	ebe080e7          	jalr	-322(ra) # 4f2 <printint>
 63c:	8bca                	mv	s7,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 63e:	4981                	li	s3,0
 640:	b745                	j	5e0 <vprintf+0x42>
        printint(fd, va_arg(ap, uint64), 10, 0);
 642:	008b8913          	addi	s2,s7,8
 646:	4681                	li	a3,0
 648:	4629                	li	a2,10
 64a:	000ba583          	lw	a1,0(s7)
 64e:	8556                	mv	a0,s5
 650:	00000097          	auipc	ra,0x0
 654:	ea2080e7          	jalr	-350(ra) # 4f2 <printint>
 658:	8bca                	mv	s7,s2
      state = 0;
 65a:	4981                	li	s3,0
 65c:	b751                	j	5e0 <vprintf+0x42>
        printint(fd, va_arg(ap, int), 16, 0);
 65e:	008b8913          	addi	s2,s7,8
 662:	4681                	li	a3,0
 664:	4641                	li	a2,16
 666:	000ba583          	lw	a1,0(s7)
 66a:	8556                	mv	a0,s5
 66c:	00000097          	auipc	ra,0x0
 670:	e86080e7          	jalr	-378(ra) # 4f2 <printint>
 674:	8bca                	mv	s7,s2
      state = 0;
 676:	4981                	li	s3,0
 678:	b7a5                	j	5e0 <vprintf+0x42>
 67a:	e062                	sd	s8,0(sp)
        printptr(fd, va_arg(ap, uint64));
 67c:	008b8c13          	addi	s8,s7,8
 680:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 684:	03000593          	li	a1,48
 688:	8556                	mv	a0,s5
 68a:	00000097          	auipc	ra,0x0
 68e:	e46080e7          	jalr	-442(ra) # 4d0 <putc>
  putc(fd, 'x');
 692:	07800593          	li	a1,120
 696:	8556                	mv	a0,s5
 698:	00000097          	auipc	ra,0x0
 69c:	e38080e7          	jalr	-456(ra) # 4d0 <putc>
 6a0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6a2:	00000b97          	auipc	s7,0x0
 6a6:	53eb8b93          	addi	s7,s7,1342 # be0 <digits>
 6aa:	03c9d793          	srli	a5,s3,0x3c
 6ae:	97de                	add	a5,a5,s7
 6b0:	0007c583          	lbu	a1,0(a5)
 6b4:	8556                	mv	a0,s5
 6b6:	00000097          	auipc	ra,0x0
 6ba:	e1a080e7          	jalr	-486(ra) # 4d0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6be:	0992                	slli	s3,s3,0x4
 6c0:	397d                	addiw	s2,s2,-1
 6c2:	fe0914e3          	bnez	s2,6aa <vprintf+0x10c>
        printptr(fd, va_arg(ap, uint64));
 6c6:	8be2                	mv	s7,s8
      state = 0;
 6c8:	4981                	li	s3,0
 6ca:	6c02                	ld	s8,0(sp)
 6cc:	bf11                	j	5e0 <vprintf+0x42>
        s = va_arg(ap, char*);
 6ce:	008b8993          	addi	s3,s7,8
 6d2:	000bb903          	ld	s2,0(s7)
        if(s == 0)
 6d6:	02090163          	beqz	s2,6f8 <vprintf+0x15a>
        while(*s != 0){
 6da:	00094583          	lbu	a1,0(s2)
 6de:	c9a5                	beqz	a1,74e <vprintf+0x1b0>
          putc(fd, *s);
 6e0:	8556                	mv	a0,s5
 6e2:	00000097          	auipc	ra,0x0
 6e6:	dee080e7          	jalr	-530(ra) # 4d0 <putc>
          s++;
 6ea:	0905                	addi	s2,s2,1
        while(*s != 0){
 6ec:	00094583          	lbu	a1,0(s2)
 6f0:	f9e5                	bnez	a1,6e0 <vprintf+0x142>
        s = va_arg(ap, char*);
 6f2:	8bce                	mv	s7,s3
      state = 0;
 6f4:	4981                	li	s3,0
 6f6:	b5ed                	j	5e0 <vprintf+0x42>
          s = "(null)";
 6f8:	00000917          	auipc	s2,0x0
 6fc:	3b890913          	addi	s2,s2,952 # ab0 <malloc+0x260>
        while(*s != 0){
 700:	02800593          	li	a1,40
 704:	bff1                	j	6e0 <vprintf+0x142>
        putc(fd, va_arg(ap, uint));
 706:	008b8913          	addi	s2,s7,8
 70a:	000bc583          	lbu	a1,0(s7)
 70e:	8556                	mv	a0,s5
 710:	00000097          	auipc	ra,0x0
 714:	dc0080e7          	jalr	-576(ra) # 4d0 <putc>
 718:	8bca                	mv	s7,s2
      state = 0;
 71a:	4981                	li	s3,0
 71c:	b5d1                	j	5e0 <vprintf+0x42>
        putc(fd, c);
 71e:	02500593          	li	a1,37
 722:	8556                	mv	a0,s5
 724:	00000097          	auipc	ra,0x0
 728:	dac080e7          	jalr	-596(ra) # 4d0 <putc>
      state = 0;
 72c:	4981                	li	s3,0
 72e:	bd4d                	j	5e0 <vprintf+0x42>
        putc(fd, '%');
 730:	02500593          	li	a1,37
 734:	8556                	mv	a0,s5
 736:	00000097          	auipc	ra,0x0
 73a:	d9a080e7          	jalr	-614(ra) # 4d0 <putc>
        putc(fd, c);
 73e:	85ca                	mv	a1,s2
 740:	8556                	mv	a0,s5
 742:	00000097          	auipc	ra,0x0
 746:	d8e080e7          	jalr	-626(ra) # 4d0 <putc>
      state = 0;
 74a:	4981                	li	s3,0
 74c:	bd51                	j	5e0 <vprintf+0x42>
        s = va_arg(ap, char*);
 74e:	8bce                	mv	s7,s3
      state = 0;
 750:	4981                	li	s3,0
 752:	b579                	j	5e0 <vprintf+0x42>
 754:	74e2                	ld	s1,56(sp)
 756:	79a2                	ld	s3,40(sp)
 758:	7a02                	ld	s4,32(sp)
 75a:	6ae2                	ld	s5,24(sp)
 75c:	6b42                	ld	s6,16(sp)
 75e:	6ba2                	ld	s7,8(sp)
    }
  }
}
 760:	60a6                	ld	ra,72(sp)
 762:	6406                	ld	s0,64(sp)
 764:	7942                	ld	s2,48(sp)
 766:	6161                	addi	sp,sp,80
 768:	8082                	ret

000000000000076a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 76a:	715d                	addi	sp,sp,-80
 76c:	ec06                	sd	ra,24(sp)
 76e:	e822                	sd	s0,16(sp)
 770:	1000                	addi	s0,sp,32
 772:	e010                	sd	a2,0(s0)
 774:	e414                	sd	a3,8(s0)
 776:	e818                	sd	a4,16(s0)
 778:	ec1c                	sd	a5,24(s0)
 77a:	03043023          	sd	a6,32(s0)
 77e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 782:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 786:	8622                	mv	a2,s0
 788:	00000097          	auipc	ra,0x0
 78c:	e16080e7          	jalr	-490(ra) # 59e <vprintf>
}
 790:	60e2                	ld	ra,24(sp)
 792:	6442                	ld	s0,16(sp)
 794:	6161                	addi	sp,sp,80
 796:	8082                	ret

0000000000000798 <printf>:

void
printf(const char *fmt, ...)
{
 798:	711d                	addi	sp,sp,-96
 79a:	ec06                	sd	ra,24(sp)
 79c:	e822                	sd	s0,16(sp)
 79e:	1000                	addi	s0,sp,32
 7a0:	e40c                	sd	a1,8(s0)
 7a2:	e810                	sd	a2,16(s0)
 7a4:	ec14                	sd	a3,24(s0)
 7a6:	f018                	sd	a4,32(s0)
 7a8:	f41c                	sd	a5,40(s0)
 7aa:	03043823          	sd	a6,48(s0)
 7ae:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7b2:	00840613          	addi	a2,s0,8
 7b6:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7ba:	85aa                	mv	a1,a0
 7bc:	4505                	li	a0,1
 7be:	00000097          	auipc	ra,0x0
 7c2:	de0080e7          	jalr	-544(ra) # 59e <vprintf>
}
 7c6:	60e2                	ld	ra,24(sp)
 7c8:	6442                	ld	s0,16(sp)
 7ca:	6125                	addi	sp,sp,96
 7cc:	8082                	ret

00000000000007ce <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7ce:	1141                	addi	sp,sp,-16
 7d0:	e422                	sd	s0,8(sp)
 7d2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7d4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7d8:	00001797          	auipc	a5,0x1
 7dc:	c187b783          	ld	a5,-1000(a5) # 13f0 <freep>
 7e0:	a02d                	j	80a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7e2:	4618                	lw	a4,8(a2)
 7e4:	9f2d                	addw	a4,a4,a1
 7e6:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7ea:	6398                	ld	a4,0(a5)
 7ec:	6310                	ld	a2,0(a4)
 7ee:	a83d                	j	82c <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7f0:	ff852703          	lw	a4,-8(a0)
 7f4:	9f31                	addw	a4,a4,a2
 7f6:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 7f8:	ff053683          	ld	a3,-16(a0)
 7fc:	a091                	j	840 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7fe:	6398                	ld	a4,0(a5)
 800:	00e7e463          	bltu	a5,a4,808 <free+0x3a>
 804:	00e6ea63          	bltu	a3,a4,818 <free+0x4a>
{
 808:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 80a:	fed7fae3          	bgeu	a5,a3,7fe <free+0x30>
 80e:	6398                	ld	a4,0(a5)
 810:	00e6e463          	bltu	a3,a4,818 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 814:	fee7eae3          	bltu	a5,a4,808 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 818:	ff852583          	lw	a1,-8(a0)
 81c:	6390                	ld	a2,0(a5)
 81e:	02059813          	slli	a6,a1,0x20
 822:	01c85713          	srli	a4,a6,0x1c
 826:	9736                	add	a4,a4,a3
 828:	fae60de3          	beq	a2,a4,7e2 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 82c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 830:	4790                	lw	a2,8(a5)
 832:	02061593          	slli	a1,a2,0x20
 836:	01c5d713          	srli	a4,a1,0x1c
 83a:	973e                	add	a4,a4,a5
 83c:	fae68ae3          	beq	a3,a4,7f0 <free+0x22>
    p->s.ptr = bp->s.ptr;
 840:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 842:	00001717          	auipc	a4,0x1
 846:	baf73723          	sd	a5,-1106(a4) # 13f0 <freep>
}
 84a:	6422                	ld	s0,8(sp)
 84c:	0141                	addi	sp,sp,16
 84e:	8082                	ret

0000000000000850 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 850:	7139                	addi	sp,sp,-64
 852:	fc06                	sd	ra,56(sp)
 854:	f822                	sd	s0,48(sp)
 856:	f426                	sd	s1,40(sp)
 858:	ec4e                	sd	s3,24(sp)
 85a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 85c:	02051493          	slli	s1,a0,0x20
 860:	9081                	srli	s1,s1,0x20
 862:	04bd                	addi	s1,s1,15
 864:	8091                	srli	s1,s1,0x4
 866:	0014899b          	addiw	s3,s1,1
 86a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 86c:	00001517          	auipc	a0,0x1
 870:	b8453503          	ld	a0,-1148(a0) # 13f0 <freep>
 874:	c915                	beqz	a0,8a8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 876:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 878:	4798                	lw	a4,8(a5)
 87a:	08977e63          	bgeu	a4,s1,916 <malloc+0xc6>
 87e:	f04a                	sd	s2,32(sp)
 880:	e852                	sd	s4,16(sp)
 882:	e456                	sd	s5,8(sp)
 884:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 886:	8a4e                	mv	s4,s3
 888:	0009871b          	sext.w	a4,s3
 88c:	6685                	lui	a3,0x1
 88e:	00d77363          	bgeu	a4,a3,894 <malloc+0x44>
 892:	6a05                	lui	s4,0x1
 894:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 898:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 89c:	00001917          	auipc	s2,0x1
 8a0:	b5490913          	addi	s2,s2,-1196 # 13f0 <freep>
  if(p == (char*)-1)
 8a4:	5afd                	li	s5,-1
 8a6:	a091                	j	8ea <malloc+0x9a>
 8a8:	f04a                	sd	s2,32(sp)
 8aa:	e852                	sd	s4,16(sp)
 8ac:	e456                	sd	s5,8(sp)
 8ae:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 8b0:	00001797          	auipc	a5,0x1
 8b4:	b5078793          	addi	a5,a5,-1200 # 1400 <base>
 8b8:	00001717          	auipc	a4,0x1
 8bc:	b2f73c23          	sd	a5,-1224(a4) # 13f0 <freep>
 8c0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8c2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8c6:	b7c1                	j	886 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 8c8:	6398                	ld	a4,0(a5)
 8ca:	e118                	sd	a4,0(a0)
 8cc:	a08d                	j	92e <malloc+0xde>
  hp->s.size = nu;
 8ce:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8d2:	0541                	addi	a0,a0,16
 8d4:	00000097          	auipc	ra,0x0
 8d8:	efa080e7          	jalr	-262(ra) # 7ce <free>
  return freep;
 8dc:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8e0:	c13d                	beqz	a0,946 <malloc+0xf6>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8e2:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8e4:	4798                	lw	a4,8(a5)
 8e6:	02977463          	bgeu	a4,s1,90e <malloc+0xbe>
    if(p == freep)
 8ea:	00093703          	ld	a4,0(s2)
 8ee:	853e                	mv	a0,a5
 8f0:	fef719e3          	bne	a4,a5,8e2 <malloc+0x92>
  p = sbrk(nu * sizeof(Header));
 8f4:	8552                	mv	a0,s4
 8f6:	00000097          	auipc	ra,0x0
 8fa:	b9a080e7          	jalr	-1126(ra) # 490 <sbrk>
  if(p == (char*)-1)
 8fe:	fd5518e3          	bne	a0,s5,8ce <malloc+0x7e>
        return 0;
 902:	4501                	li	a0,0
 904:	7902                	ld	s2,32(sp)
 906:	6a42                	ld	s4,16(sp)
 908:	6aa2                	ld	s5,8(sp)
 90a:	6b02                	ld	s6,0(sp)
 90c:	a03d                	j	93a <malloc+0xea>
 90e:	7902                	ld	s2,32(sp)
 910:	6a42                	ld	s4,16(sp)
 912:	6aa2                	ld	s5,8(sp)
 914:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 916:	fae489e3          	beq	s1,a4,8c8 <malloc+0x78>
        p->s.size -= nunits;
 91a:	4137073b          	subw	a4,a4,s3
 91e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 920:	02071693          	slli	a3,a4,0x20
 924:	01c6d713          	srli	a4,a3,0x1c
 928:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 92a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 92e:	00001717          	auipc	a4,0x1
 932:	aca73123          	sd	a0,-1342(a4) # 13f0 <freep>
      return (void*)(p + 1);
 936:	01078513          	addi	a0,a5,16
  }
}
 93a:	70e2                	ld	ra,56(sp)
 93c:	7442                	ld	s0,48(sp)
 93e:	74a2                	ld	s1,40(sp)
 940:	69e2                	ld	s3,24(sp)
 942:	6121                	addi	sp,sp,64
 944:	8082                	ret
 946:	7902                	ld	s2,32(sp)
 948:	6a42                	ld	s4,16(sp)
 94a:	6aa2                	ld	s5,8(sp)
 94c:	6b02                	ld	s6,0(sp)
 94e:	b7f5                	j	93a <malloc+0xea>
