#include "Vtop.h"
#include "verilated.h"

int main(int argc, char** argv, char** env)
{
	Verilated::mkdir("logs");
	VerilatedContext* contextp = new VerilatedContext;
	contextp->traceEverOn(true);
	contextp->commandArgs(argc, argv);
	Vtop* top = new Vtop{contextp};
	top->rst = 0;
    while (!contextp->gotFinish())
	{
        top->clk = 1;
        contextp->timeInc(1);
        top->eval();
        top->clk = 0;
        contextp->timeInc(1);
        top->eval();
    }
	delete top;
	delete contextp;
	return 0;
}
