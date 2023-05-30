
# Project Title

A brief description of what this project does and who it's for

The aim of this work is the implementation of a functional
digital system. The system will consist of a subsystem
Transmitter - Receiver (Tx - Rx) with UART communication protocol and a
Driver that will display data on LED displays.Data will be received from sensors, which will be encoded and
coded and sent by the Transmitter , will be received by the Receiver which will
and if there is no error, the receiver will receive the data and check that the protocol is being followed.
will be displayed on the screens.

Starting from the Driver.

The LED Driver will accept as input the data from the Receiver in the format
8-bit words, will process them so that they can be displayed on the screens and
activate the displays {DISP3 , DISP2 , DISP1 , DISP0} in an appropriate manner
so that with 7-bit output and 4 bits for the activation signals of the screens {AN3 ,
AN2 , AN1 , AN0} to display the following characters on the monitors.
{0, 1, 2, 3, 4, 5, 6, 7, 8, 9, F, -, "blank"}

Comments:

The use of screen activation signals allows us to channel
to each screen, the same [6:0] LED signals, so that we can display whatever message
without needing 4 different [6:0] LED signals for each
display. Turning the screens on and off is done in a staggered manner
of a few hundred nanoseconds, so to the human eye, the screens,
appear to be constantly on. In addition, each screen has internal
capacitors which, after turning off the corresponding anodes,
hold the display until the next activation. The minimum time
charging of the capacitors is 320ns.

UART System

The system will consist of a UART Transmitter and a UART
Receiver , which carry data in one direction, from the
Transmitter to the Receiver, via a single-signal serial connection.
The UART to be implemented will be used for the serial
transfer of at least one sequence of four different
symbols, usually 8-bit, from the Transmitter to the Receiver.
the context of the task the signals will be sent from the
Transmitter to Receiver in 2 8-bit packets. More specifically if
for example the sensor reading is '-888' then the two packets
8-bit packets will be '-8' and '88'.
The UART (Universal Asynchronous Receiver Transmitter
Asynchronous Receiver and Transmitter) is a serial, asynchronous
communication protocol, which allows data transfer
between two (or more generic) devices, which may be
have independent and unrelated clocks. Asynchronous communication
of UART is accomplished via a one-bit wired connection,
between the Transmitter (TxD), which drives it, and the Receiver (RxD),
which samples and examines it. The data to be communicated,
is usually called a symbol, and to be sent serially
it must be converted into its constituent digits, which will
sent one by one, from the smallest (LSB) to the largest (MSB)

For the correct sampling rate, so that no samples are lost or
data is lost or duplicated in the UART protocol, the Sender and
Receiver shall pre-agree on the speed of their communication with each other at
units of Baud (bits/sec); the period of each digit is calculated as T =
1/BaudRate. The operation and sampling of the UART is performed in
multiple of the Baud Rate. In the present implementation,
the sampling is 16*Baud Rate.The Baud Rate Controller will be used internally in the circuits
Transmitter and Receiver. We will use a 50 MHz , 20ns clock.
We want the Controller depending on the input BAUD_SEL to give us output
Baud_sample which goes from 1 vertical to 16*Baud Rate and
stay at 1 for 20ns. We will find the Minimum Common Multiple (MCP)
of the frequencies given to us, Baud Rate, and make a
counter that counts the time corresponding to the EPC.
We find that the EPC is equal to 16*Baud Rate for BAUD_SEL =
111.
This frequency corresponds to a period T = 542.5 ns. So, to
implement the controller, we need a counter that counts cycles
clock cycles up to T = 542.5 ns and a counter that counts how many times
we counted T. For several BAUD_SEL , the required frequency is
a * T , where a = Baud Rate / 115200.
However, our clock , has a period of 20ns, therefore , the closest that
we can measure is 540. So the relative error, for each
BAUD_SEL is 2.5ns * a / ( 1 / ( Baud Rate * 16 ) ) = 0.461%.

The Transmitter will receive from the sensors, data in 8-bit format
words. It will be activatable , with TX_EN control signals,
TX_WR. It will have as output, the TxD through which we have the serial
communication with the receiver and Tx_BUSY which indicates whether we are in
transmission process, so that the data is not changed and the
BAUD_SEL.

We have two states, IDLE and ACTIVE, which
determined by the TX_EN signal while the transmission mode is
part of the ACTIVE state. The protocol specifies that we send
with the sequence {start bit , data , parity , end bit} and all communication will be
last 11*T where T = 1 / Baud Rate.

The Receiver will accept the TxD as input, together with an activation signal
RX_EN and will have as output the 8-bit word read, together with signals
indicating whether the protocol was followed or in the case of
error, what error occurred. The errors we can
have are : FERROR → Frame Error and PERROR → Parity
Error.

We have two states, IDLE and ACTIVE. We'll be driven
to the ACTIVE state if we have RX_EN and the Transmitter sends the
start bit. We use this event to synchronize the
sampling. Every time we sample, we check for
FERROR. After we sample the start bit, the data and the
parity bit, we check for PERROR. If there are no errors,
we assume we received the correct message, and keep the output
our outputs stable until the next communication.

In this part we will add a module which will encode
the data before it is sent serially from the Transmitter and will
decode the data after it is read by the Receiver but before
but before it is output.
We will use a common key key for the Transmitter and the
Receiver.
The BAUD_SEL control signal is suitable for this function.
I consider [7:0] Key =
We will perform the operation DATA_OUT = DATA_IN (XOR) Key
so the Transmitter side will encode the initial
data , while on the Receiver side the same operation on the
encoded data will give us the original data.