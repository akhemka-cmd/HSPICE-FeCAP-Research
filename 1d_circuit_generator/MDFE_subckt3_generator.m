% Generates general 1D multi-domain subcircuit
% zero boundary conditions of P in the out-of-plane (z) direction


clc; clear;

%%
spice_preamble;

%%
% % non-uniform Landau coefficients
alpha_1 = -0.8e9; alpha_11 = 3.15e10; alpha_111 = 1.1e9;
per = 5/100;
alpha_I = normrnd(alpha_1,abs(alpha_1)*per,nx,ny);
alpha_II = normrnd(alpha_11,abs(alpha_11)*per,nx,ny);
alpha_III = normrnd(alpha_111,abs(alpha_111)*per,nx,ny);

eps0 = 8.8541878128e-12; kappa = 10; tFE = 20e-9;
%V0=0; vde0=-1.46; Qfe0 = -7.8e-2;
V0=0; vde0=-0.067; Qfe0 = -11.1e-2;
Pr = Qfe0 - eps0*(kappa-1)*(V0-vde0)/tFE;

%% Data file generation
dataname = 'FE_SUBCKT3';
datapath = strcat('.\',...
                    dataname,'.cir');
fid = fopen(datapath,'w');
fprintf(fid,'%5s %5s','.SUBCKT', lower(dataname));

% input output nodes
fprintf(fid,'%s\n',' n1 n2 Pz L GFF'); % electrode potentials



fprintf(fid,'\n%s',strcat('.param nx=',num2str(nx),' ny=',num2str(ny),' nz=',num2str(nz)));


if nx*ny*nz >= 10
    fprintf(fid,'\n\n%s%s','.param ','p_sum10(');
    for n = 1:10
        if n==10
            fprintf(fid,'%s',strcat('p_',num2str(n)));
        else
            fprintf(fid,'%s',strcat('p_',num2str(n),','));
        end
    end
    fprintf( fid,'%s\n%s',')=','+  ''(' );
    for n = 1:10
        if n==10
            fprintf(fid,'%s',strcat('p_',num2str(n)));
        else
            fprintf(fid,'%s',strcat('p_',num2str(n),'+'));
        end
    end
    fprintf( fid,'%s\n',')''' );
    
    if  mod(nx*ny*nz,10)~=0
        fprintf(fid,'\n%s%s','.param ','p_sum(');
    for n = 1:mod(nx*ny*nz,10)
        if n==mod(nx*ny*nz,10)
            fprintf(fid,'%s',strcat('p_',num2str(n)));
        else
            fprintf(fid,'%s',strcat('p_',num2str(n),','));
        end
    end
    fprintf( fid,'%s', ')=','''(' );
    for n = 1:mod(nx*ny*nz,10)
        if n==mod(nx*ny*nz,10)
            fprintf(fid,'%s',strcat('p_',num2str(n),')'''));
        else
            fprintf(fid,'%s',strcat('p_',num2str(n),'+'));
        end
    end
    end
    
	fprintf( fid,'\n\n\n' );
else
    
        fprintf(fid,'\n%s%s','.param ','p_sum(');
    for n = 1:nx*ny*nz
        if n==nx*ny*nz
            fprintf(fid,'%s',strcat('p_',num2str(n)));
        else
            fprintf(fid,'%s',strcat('p_',num2str(n),','));
        end
    end
    fprintf( fid,'%s', ')=','''(' );
    for n = 1:nx*ny*nz
        if n==nx*ny*nz
            fprintf(fid,'%s',strcat('p_',num2str(n),')'''));
        else
            fprintf(fid,'%s',strcat('p_',num2str(n),'+'));
        end
    end
    fprintf( fid,'\n\n\n' );
end

% subcircuit netlist with nearest neighbors
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            
        [nn_idx] = NN_index([i,j,k],[nx,ny,nz],3); % 6 nearest neighrbors
        x1 = nn_idx(1,:); x2 = nn_idx(2,:); y1 = nn_idx(3,:);
        y2 = nn_idx(4,:); z1 = nn_idx(5,:); z2 = nn_idx(6,:);
        
        if i==1 % periodic in-plane BCs for vfe
            x1 = [nx,j,k];
        elseif i==nx
            x2 = [1,j,k];
        end
        if j==1
            y1 = [i,ny,k];
        elseif j==ny
            y2 = [i,1,k];
        end
        fprintf( fid,'%s  ',strcat('Xfe_',num2str(i),'_',num2str(j),'_',num2str(k)) );
        fprintf( fid,'%s ', 'L GFF');

        
        % z direction
        if k == 1 % top electrode  
            fprintf( fid,'%s %s ', ...
                    'n1',strcat('vfe_',num2str(i),'_',num2str(j),'_',num2str(k+1)) );
        elseif k == nz % bottom electrode
            fprintf( fid,'%s %s ', ...
                    strcat('vfe_',num2str(i),'_',num2str(j),'_',num2str(k-1)), 'n2' );
        else    % central region
        	fprintf( fid,'%s %s ', ...
                    strcat('vfe_',num2str(i),'_',num2str(j),'_',num2str(k-1)),...
                    strcat('vfe_',num2str(i),'_',num2str(j),'_',num2str(k+1)) );
        end

        
        if i==1 % periodic in-plane BCs for P
            x1 = [nx,j,k];
        elseif i==nx
            x2 = [1,j,k];
        end
        if j==1
            y1 = [i,ny,k];
        elseif j==ny
            y2 = [i,1,k];
        end
        

        fprintf( fid,'\n+  ');
        fprintf( fid,'%s %s %s %s %s ',... 
                        strcat('pz_',num2str(i),'_',num2str(j),'_',num2str(k)));
        % z direction
        if k == 1
            fprintf( fid,'%s %s ',...
                    '0',...
                    strcat('pz_',num2str(z2(1)),'_',num2str(z2(2)),'_',num2str(z2(3))) );
        elseif k == nz
            fprintf( fid,'%s %s ',...
                    strcat('pz_',num2str(z1(1)),'_',num2str(z1(2)),'_',num2str(z1(3))),...
                    '0');
        else
            fprintf( fid,'%s %s ',...
                    strcat('pz_',num2str(z1(1)),'_',num2str(z1(2)),'_',num2str(z1(3))),...
                    strcat('pz_',num2str(z2(1)),'_',num2str(z2(2)),'_',num2str(z2(3)))...
                    );
        end
   

        	fprintf( fid,'\n%s  \n','+  tdgl_subckt');
            
%             ,...
%                     strcat('alpha_1=',num2str(alpha_I(i,j))),...
%                     strcat('alpha_11=',num2str(alpha_II(i,j))),...
%                     strcat('alpha_111=',num2str(alpha_III(i,j))) );

        end
    end    
end


%% call poisson solver
fprintf( fid,'\n%s\n%s','Xphi n1 n2','+  ' );
n = 0; % local voltage nodes
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            n = n+1;
            if mod(n,10)==0 && n~=nx*ny*nz
            fprintf( fid,'%s\n%s',...
                    strcat('vfe_',num2str(i),'_',num2str(j),'_',num2str(k)),'+  ' );
            else
                fprintf( fid,'%s ',...
                    strcat('vfe_',num2str(i),'_',num2str(j),'_',num2str(k)) );
            end
        end
    end
end
fprintf( fid,'\n%s','+  ' );
n = 0; % local polarization nodes
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            n = n+1;
            if mod(n,5)==0 && n~=nx*ny*nz

            fprintf( fid,'%s\n%s',...
                    strcat('pz_',num2str(i),'_',num2str(j),'_',num2str(k)),'+  ' );
            else
            fprintf( fid,'%s ',...
                    strcat('pz_',num2str(i),'_',num2str(j),'_',num2str(k)) );
            end
        end
    end
end
fprintf( fid,'\n%s\n','+  poisson_subckt' );


%% calculate average polarization (Px,Py,Pz)
A = floor(nx*ny*nz/10); B = mod(nx*ny*nz,10);


% Pz
n = 0; a = 1; c = 0; % print indicator
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            n = n + 1;

            if c==0 && (nx*ny*nz)>=10% print p_sum10 function name
                fprintf( fid,'\n%s%s',strcat('E_pz',num2str(a),' epz',num2str(a),' 0' ),...
                         ' VOL=''p_sum10(' );
                c = 1;
            end
            
            
            if mod(n,10)==0 || n==nx*ny*nz
                fprintf( fid,'%s',strcat('V(pz_',num2str(i)),'_',num2str(j),'_',num2str(k),'))''' );
                a = a+1; c = 0;
            else
                fprintf( fid,'%s',strcat('V(pz_',num2str(i)),'_',num2str(j),'_',num2str(k),'),' );
            end

            if B~=0 && a==A+1  % perform p_sum function
            	fprintf( fid,'\n%s%s',strcat('E_pz',num2str(a),' epz',num2str(a),' 0'),...
                         ' VOL=''p_sum(' );
                a = a+1; c = 1;
            end
            
        end
    end
end

fprintf( fid,'\n\n%s','E_pz Pz 0 VOL=''(' );
for a = 1 : A
    if a~=A
        fprintf( fid,'%s',strcat('V(epz',num2str(a),')+') );
    else
        fprintf( fid,'%s',strcat('V(epz',num2str(a),')') );
    end
    if mod(a,10)==0
        fprintf( fid,'\n%s  ','+');
    end
end
if B~=0
    fprintf( fid,'%s',strcat('+V(epz',num2str(A+1),')',')/(nx*ny*nz)''') );
else
    fprintf( fid,'%s',')/(nx*ny*nz)''' );
end

% total current
fprintf( fid,'\n\n%s','X_Ife n1 n2 Pz v_fe tFE=''tFE'' A=''A'' kappa=''kappa''' );




P1 = zeros(nx,ny,nz); P2 = zeros(nx,ny,nz); P3 = Pr*ones(nx,ny,nz);
phi_0 = zeros(nx,ny,nz);

n = 0;
fprintf( fid,'\n\n\n%s','.IC ' );
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            n = n+1;
            fprintf( fid,'%s ',strcat('V(vfe_',num2str(i),'_',num2str(j),'_',num2str(k),...
                                      ')=',num2str(phi_0(i,j,k),20)) );
           if n==nx*ny*nz
               fprintf(fid,'\n');
           elseif  mod(n,5)==0
                fprintf(fid,'\n%s','.IC ');
           end
        end
    end
end


n = 0;
fprintf( fid,'\n%s','.IC ' );
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            
            n = n+1;

            fprintf( fid,'%s ',strcat('V(pz_',num2str(i),'_',num2str(j),'_',num2str(k),...
                                       ')=',num2str(P3(i,j,k),20)) );
            if n ~= nx*ny*nz
                fprintf(fid,'\n%s','.IC ');
            end
        end
    end
end


fprintf(fid,'\n\n\n%s','.ENDS');
fclose(fid);

