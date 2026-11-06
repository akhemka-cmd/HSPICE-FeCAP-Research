Inside 1d_circuit_generator folder

	set number of grid points  nz
	Run MDFE_subckt3_generator.m and poisson_subckt_generator.m
	copy generated FE_SUBCKT3.cir and POISSON_SUBCKT.cir to circuit_files folder

************************************************
Inside circuit_files folder
	inside HZO_MD.sp file update .param dz=1.0e-9 if necessary, dz= thickness of ferroelectric (tfe)/number of grid points (nz)
	
************************************************
Copy all the circuit_files folder to the server

************************************************ 
in the server 
first source setup file for hspice running the following command
source /tools/software/synopsys/setup.csh

then inside the circuit_files folder run the following command to run the simulation

hspice -i HZO_MD.sp

to see the generated result waveforms wun the following command 
wv&
browse the file HZO_MD.tr0 in the waveform browser look into v(va),v(fe),v(pz)