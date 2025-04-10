# I2C_Hardware_Modelling-Verilog-

I made a simple i2c communication protocol using verilog HDL in Vivado.
For now it only transmit data from master to slave only.
slave doesn't have any storage system(just a 8-bit REG for now) to store transmitted data nor it can send data to master.

the aim of the project is to show the basic working of SDA and SCL and their syncronization.

output waveform:-
ACK:-
![Screenshot_20250323_024431](https://github.com/user-attachments/assets/d00df02a-c578-42eb-8f7f-b12acef1e605)

NACK:-
![Screenshot_20250323_031852](https://github.com/user-attachments/assets/7bd73b08-e99d-4798-beca-90a3e20d8967)


