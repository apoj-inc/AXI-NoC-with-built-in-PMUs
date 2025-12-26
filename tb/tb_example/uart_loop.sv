module uart_loop
#(
	parameter CLK_FRE = 50,      //clock frequency(Mhz)
	parameter BAUD_RATE = 115200 //serial baud rate
)
(
	input                        clk,              //тактовый сигнал
	input                        rst_n,            // асинхронный сброс, низкий уровень активности


	input[7:0]                   tx_data,          //данные для отправки
	input                        tx_data_valid,    //начать отправку данных
	output reg                   tx_data_ready,    //флаг отправки
	//output                       tx_pin,           //вывод передатчика


	output reg[7:0]              rx_data,          //полученные данные
	output reg                   rx_data_valid,    //флаг приема данных
	input                        rx_data_ready     //начать прием
	//input                        rx_pin            //ввод приемника
);


wire uart_line;


uart_rx urx //передатчик
(
	.clk(clk),
	.rst_n(rst_n),
	.rx_data(rx_data),
	.rx_data_valid(rx_data_valid),
	.rx_data_ready(rx_data_ready),
	.rx_pin(uart_line)
);


uart_tx utx //приемник
(
	.clk(clk),
	.rst_n(rst_n),
	.tx_data(tx_data),
	.tx_data_valid(tx_data_valid),
	.tx_data_ready(tx_data_ready),
	.tx_pin(uart_line)
);


endmodule
