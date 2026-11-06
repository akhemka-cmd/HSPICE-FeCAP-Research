
**** simulates multi-domain switching of ferroelectric materials ****
**** 1D version 
**** + series dielectric dead layer (DL_SUBCKT.cir), no leakage

.option post
.option ACCURATE=1
.option MEASFORM=3
.option POST_VERSION=9601
.option runlvl=6
*.option PROBE
*.option MEASFILE=1

**** load models & subcircuits
.INCLUDE "FE_SUBCKT3.cir"
.INCLUDE "POISSON_SUBCKT.cir"
.INCLUDE "TDGL_SUBCKT.cir"
.INCLUDE "DL_SUBCKT.cir"


**** load verilog-a files
.hdl "CONTACT.va"
.hdl "V_FE.va"
 
**** universal constants
.param  ep0  	= 8.854187817e-12 $ vaccum dielectric constant (F/m)
.param  kB	= 1.38064852e-23 $ Boltzmann constant (J/K)
.param	T   	= 300	$ temperature (K)

**** device parameters
.param  tFE		= 10e-9	$ FE thickness (m)
.param  A		= 7e-9 	$ capacitor area (m^2)
.param	lambda_1	= 0.05n		lambda_2 = 0.05n 

.param	ep_1		= 8.45		ep_2 = 8.45
*.param  K		= '1/(ep0 + tFE/(lambda_1/ep_1/ep0+lambda_2/ep_2/ep0))/2'

.param  kappa		= 35

**** dead layer parameters
.param  Cdl_area	= 0.35	$ dead-layer capacitance per area (F/m^2), EOT ~ 0.1 nm (Hsu et al.)
*                                 set to 1e3 to recover the original model (regression check)



**** material parameters
.param  Ps 		= 0.25
.param  alpha_1	   	= -4e8 
.param  alpha_11   	= 3.7e9
.param  alpha_12   	= 0
.param  alpha_111  	= 1.1e9
.param 	alpha_112  	= 0
.param	alpha_123  	= 0


.param L_base=50e-6
.param L_multiplier=1.6e-8
* changed from L_multiplier=1.527e-8

.param G_base=1.8e-9
.param G_multiplier=-.2e-9
.param c1= 6e-9
.param c2=1
.param cm=1.5
.param small=1e-3

**** grid size (m)

.param dz=1.0e-9

**** input source parameters
.param Vs = 4
.param td = 4u   tr = 1u
.param t_end = 100u


************ Main circuit netlist ************

Vs va 0 pulse('-Vs' 'Vs' 't_end' 't_end' 't_end' '0' 't_end*2')  $ input gate 
Rs va vfe 20k  $ series resistor

**** dead layer (between series resistor and top contact)
Xdl vfe vdl dl_subckt	Cdl_area='Cdl_area' tFE='tFE' A='A' kappa='kappa' ep0='ep0'
+			lambda_1='lambda_1' ep_1='ep_1' lambda_2='lambda_2' ep_2='ep_2' pz0='pz0'

**** multi-domain subcircuit
Xcon1 vdl n1 pz contact	tFE='tFE' A='A'
+			lambda_1='lambda_1' ep_1='ep_1' lambda_2='lambda_2' ep_2='ep_2' con=1
Xfe_md n1 n2 pz L GFF fe_subckt3
Xcon2 n2 0 pz contact	tFE='tFE' A='A'
+			lambda_1='lambda_1' ep_1='ep_1' lambda_2='lambda_2' ep_2='ep_2' con=2



************ Transient analysis ************
.param V0=0 px0=0.1906 py0=-0.1906 pz0=-0.111276

**** self-consistent initial state with dead layer (0 V bias, Pz = pz0)
.param Cbg_m	= 'ep0*kappa/tFE'					$ FE background capacitance per area
.param kscr_m	= '1/(1 + lambda_1/(ep_1*tFE) + lambda_2/(ep_2*tFE))'
.param Vscr1_0	= 'pz0*kscr_m*lambda_1/(ep0*ep_1)'			$ top contact screening drop
.param Vscr2_0	= 'pz0*kscr_m*lambda_2/(ep0*ep_2)'			$ bottom contact screening drop
.param Vfe0_m	= '-(pz0/Cdl_area + Vscr1_0 + Vscr2_0)/(1 + Cbg_m/Cdl_area)'	$ V(n1,n2) at t=0
.param Vdl0_m	= '(Cbg_m*Vfe0_m + pz0)/Cdl_area'			$ V(vfe,vdl) at t=0


**** initial conditions
.IC V(va)='V0' V(vfe)='V0'
.IC V(pz)='pz0'
.IC V(vdl)='V0 - Vdl0_m'
.IC V(n1)='V0 - Vdl0_m - Vscr1_0'
.IC V(n2)='Vscr2_0'
.IC V(ZD)='0'
.IC V(L)='L_base'
.IC V(GFF)='G_base'

*L circuit
EZ ZD 0 VOL='v(pz)'
CZ ZD 0 'L_multiplier'
HL L1 0 POLY(1) EZ 0 1 0 MAX=15e-4 ABS=1   
VL Lx L1 'L_base'
RL Lx L 1k
CL L 0 2n


*G11 circuit (uses V(n1,n2) = voltage across FE only, excludes dead layer)
EG G 0 POLY(1) n1 n2 0 1 ABS=1
RG G 0 1

EGF GF 0 VOL='v(G)'
RGF GF 0 1

EGFF GX 0 VOL='G_base+c1*exp(-((V(GF)-cm)/c2)^4)'
RGFF GX GFF 1k
CGFF GFF 0 20n 

.param TSTEP=1n  TSTOP='t_end*6'
.TRAN 'TSTEP' 'TSTOP' UIC 

**** v(vfe)     : terminal voltage of capacitor (compare to experiment)
**** v(n1,n2)   : voltage across FE layer only
**** v(vfe,vdl) : voltage across dead layer
.probe TRAN v(va) v(vfe) v(vdl) v(pz) v(GFF) v(n1,n2) v(vfe,vdl)
+	D=PAR('ep0*kappa*v(n1,n2)/tFE+v(pz)') i(Rs) i(CZ) 

.end
