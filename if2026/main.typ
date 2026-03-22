#import "@preview/diatypst:0.9.1": *
#import "@preview/treet:1.0.0": *

#show: slides.with(
  title: "NuttX aneb RTOS pro embedded nadšence i profíky", // Required
  subtitle: "Installfest 2026",
  footer-title: "Installfest 2026",
  footer-subtitle: "NuttX aneb RTOS pro embedded nadšence i profíky",
  date: "28. 3. 2026",
  authors: ("Michal Lenc"),

  // Optional Styling (for more / explanation see in the typst universe)
  ratio: 16/9,
  layout: "small",
  title-color: blue.darken(60%),
  toc: false,
  theme: "full",
  count: "number",
  first-slide: true
)

== Možnosti embedded programování

bare metal programování

výrobci poskytnuté HALy (hardware abstraction layer)

*operační systémy navržené pro embedded*
- kombinace HAL a API
- konzole, vlákna, POSIX, file systém

#columns(3)[
  #image("figs/nuttx-logo.svg", height: 3.0cm)
#colbreak()
  #image("figs/rtems-logo.svg", height: 2.3cm)
#colbreak()
  #image("figs/zephyr-logo.svg", height: 2.5cm)
]

= Operační systém NuttX

== Úvod

- operační systém reálného času (RTOS)
  - https://nuttx.apache.org/
- dostupný pod licencí Apache License 2.0 (projekt do ASF plně zařazen v roce 2022)

#columns(2)[
  - autorem je Gregory Nutt
  - první verze publikována v roce 2007
  - velmi aktivní komunita (poslední měsíc 218 commitů od 46 autorů)
  - kernel psaný v C, Kconfig syntaxe
  - aplikace podpora C++, omezeně i Python, Lua, Rust
#colbreak()
  #image("figs/nuttx-logo.svg", height: 5.0cm)
]

#pagebreak()

- téměř plně kompatibilní s POSIX API
- snaha o kompatibilitu s GNU/Linux (`epoll`, `inotify`, ...)
- šiřoká podpora architektur (ARM, RISC-V, Xtensa, AVR), mikrokontrolérů a vývojových kitů
  - ne všechny MCU mají dopsanou podporu pro všechny periferie!
- ovladače děleny na lower layer (specifické pro daný čip) a upper layer (společná vrstva)
- obecně dobrá kompartmentace zdrojového kódu
- velká variabilita v konfiguraci pomocí Kconfig
  - minimální build cca 32 kB flash a RAM 
- vlastní shell jako aplikace v rámci jedné binárky
- networking, TCP/IP, DHCP, telnet, file systémy (FAT, LittleFS)

== NuttShell (NSH)

- konfigurovatelná aplikace a knihovna poskytující shell applikaci

  #show raw: set text(size: 6pt)
  ```shell
  NuttShell (NSH) NuttX-12.4.0
  nsh> ps
  PID GROUP PRI POLICY   TYPE    NPX STATE    EVENT     SIGMASK           STACK   USED  FILLED COMMAND
    0     0   0 FIFO     Kthread   - Ready              0000000000000000 002032 000824  40.5%  Idle_Task
    1     1 100 RR       Task      - Running            0000000000000000 003024 002160  71.4%  nsh_main
  nsh> free
                     total       used       free    maxused    maxfree  nused  nfree
          Umem:   33294936      22232   33272704      47256   33272672     45      2
  nsh> ls
  /:
   dev/
   proc/
  nsh> ls dev
  /dev:
   console
   null
   zero
  ```

#pagebreak()
#columns(2)[
  - dostupný na UART, CDC/ACM, telnet
  - monitorování a správa tasků (`ps`, `kill`)
  - debugování, logování (`setlogmask`)
  - správa souborů (`mount`, `mkdir`, `cat`)
  - nastavení sítě (`ifconfig`, `ifup`, ...)
  - možnost spouštět aplikace na pozadí pomocí `&`
#colbreak()
  #image("figs/nuttx-shell.svg", height: 5.0cm)
]

Webová demo ukázka - https://nuttx.apache.org/demo/.

== Ovladače periferií

- lower half (specifická pro daný čip) a upper half (společná část)
- aplikace interaguje s upper half pomocí POSIX API

#align(center, image("figs/nuttx-drivers.svg", height: 5.0cm))

#pagebreak()

- standardní POSIX API kompatibilní s GNU/Linux (UART, socket, poll)

#show raw: set text(size: 8pt)
```c
uint8_t answer = 42;
int fd = open("/dev/muj_uart", O_RDWR);
int ret = write(fd, &answer, sizeof(answer));
```
- read/write struktur speciálních pro NuttX (ADC, CAN) nebo speciální ioctl (PWM, GPIO)

```c
int fd = open("/dev/moje_gpio", O_RDONLY);
int ret = ioctl(fd, GPIOC_WRITE, true);
```

```c
struct adc_msg_s sample;
int fd = open("/dev/muj_adc_senzor", O_RDONLY);
int ret = read(fd, &sample, sizeof(sample));
```

== Organizace zdrojového kódu

#columns(2)[
 - `arch` obsahuje obecnou implementaci mikrokontroléru a lower half vrstvy ovladačů
   - lower half vrstvy často duplikovány pro různé MCU, přestože jsou vlastně stejné
 - `drivers` obsahuje společné upper half vrstvy ovladačů
 - `boards` implementuje jednotlivé desky a zajišťuje inicializaci periferií
   - opět častá duplikace
 - aplikace v separátním `apps` repozitáři
#colbreak()
#tree-list[
  - arch
    - arm
    - riscv
    - ...
  - drivers
    - analog
    - spi
    - ...
  - boards
    - arm
    - riscv
    - ...
]
]

== Konfigurace

#columns(2)[
- Kconfig syntaxe převzatá z jádra Linuxu
- konfigurace periferií, sítě, file systémů, aplikací, jádra
- téměř každá funkcionalita jde vypnout
- může být složitější na orientaci
- některé volby špatně dokumentované
- občas problémy se závislosti
 - v lepším případě se poznají chybou při kompilaci, v horším
   až v runtime hard faultem
- desky mají předpřipravené demo konfigurace

#colbreak()
  #image("figs/nuttx-config.png", height: 7.0cm)
]

== Kompilace

- potřeba repozitáře `nuttx` (kernel a ovladače) a `apps` (NuttShell apod)

```console
git clone https://github.com/apache/nuttx.git nuttx
git clone https://github.com/apache/nuttx-apps.git apps
```

- konfigurace se provádí přes script v repozitáři `nuttx`

```console
./tools/configure.sh nucleo-l476rg:nsh
```

- všechny desky mají připravenou `nsh` konfiguraci obsahující základní
  build s NuttShellem
- většinou dostupné i další konfigurace s nakonfigurovanými periferiemi
- dobré pokrytí u ARM a RISC-V procesorů a desek

== Jenom na hraní?

#columns(3)[
  - NuttX lze najít na mnoha místech v průmyslu
  - Elektroline (tramvajové systémy)
  - IoT systémy Sony Spressense
  - PX4 pro řízení dronů
  - ECU jednotky pro LiAuto
  - OpenVela od Xiaomi postavená na kernelu NuttXu
  - řízení motorů na ČVUT FEL
#colbreak()
  #image("figs/ell-logo.svg")
  #image("figs/li-logo.svg", height: 1.3cm)
  #image("figs/espressif-logo.svg", height: 2.5cm)
#colbreak()
  #image("figs/xiaomi-logo.svg", height: 3.0cm)
  #image("figs/px4-logo.svg", height: 2.0cm)
  #image("figs/sony-logo.svg", height: 0.8cm)
]

== Vyzkoušejte si NuttX

Praktický workshop s úvodem do programování s NuttXem po přednášce v
učebně KN-A:424.

Vyzkoušíme si konfiguraci, kompilaci a použití LED, PWM, ADC a GPIO periferií.

*K dispozici bude 25 kusů desek NUCLEO-L476RG poskytnutých pražskou
pobočkou firmy STMicroelectronics.*

#align(center, image("figs/nucleo-board.jpg", height: 3.5cm))
