
clc; clear;


%%
spice_preamble;


%% Data file generation
dataname = 'POISSON_SUBCKT';
datapath = strcat('.\',...
                    dataname,'.cir');
fid = fopen(datapath,'w');
fprintf(fid,'%s\n',strcat('**** nx=',num2str(nx),' ny=',num2str(ny),' nz=',num2str(nz)));
fprintf(fid,'%s %s %s','.SUBCKT', lower(dataname),'  ');

% input output nodes
fprintf(fid,'%s\n%s','n1 n2','+  ');  % boundary potential nodes
n = 0;
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            
            n = n+1;
            if mod(n,10)==0 && n~=nx*ny*nz
            fprintf( fid,'%s\n%s',strcat('phi_',num2str(i),'_',num2str(j),'_',num2str(k)),'+  ' );
            else
            fprintf( fid,'%s%s',strcat('phi_',num2str(i),'_',num2str(j),'_',num2str(k)),' ' );
            end
            
        end
    end
end
fprintf(fid,'\n%s','+  ');
% local polarization nodes
n = 0;
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
            
            n = n+1;
            if mod(n,5)==0 && n~=(nx*ny*nz)
            %fprintf( fid,'%s',strcat('px_',num2str(i),'_',num2str(j),'_',num2str(k)),' ' );
            %fprintf( fid,'%s',strcat('py_',num2str(i),'_',num2str(j),'_',num2str(k)),' ' );
            fprintf( fid,'%s\n%s',strcat('pz_',num2str(i),'_',num2str(j),'_',num2str(k)),'+  ' );
            else
            %fprintf( fid,'%s ',strcat('px_',num2str(i),'_',num2str(j),'_',num2str(k)) );
            %fprintf( fid,'%s ',strcat('py_',num2str(i),'_',num2str(j),'_',num2str(k)) );
            fprintf( fid,'%s ',strcat('pz_',num2str(i),'_',num2str(j),'_',num2str(k)) );
            end
            
        end
    end
end

fprintf( fid,'\n\n\n%s\n\n','.param R_phi=''1/( 2/(dz*dz) )''');


% subcircuit netlist
for k = 1:nz
    for j = 1:ny
        for i = 1:nx
        
        [nn_idx] = NN_index([i,j,k],[nx,ny,nz],3); % 6 nearest neighrbors
        x1 = nn_idx(1,:); x2 = nn_idx(2,:); y1 = nn_idx(3,:);
        y2 = nn_idx(4,:); z1 = nn_idx(5,:); z2 = nn_idx(6,:);
        
        fprintf( fid,'%s  %s  %s  %s\n',...
                    strcat('Rphi_',num2str(i),'_',num2str(j),'_',num2str(k)),...
                    strcat('phi_',num2str(i),'_',num2str(j),'_',num2str(k)),...
                    '0','1' );

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
        
        fprintf(fid,strcat(repmat('%s',1,11)),...
                strcat('Gphi_',num2str(i),'_',num2str(j),'_',num2str(k)),...
                '  0  ',strcat('phi_',num2str(i),'_',num2str(j),'_',num2str(k)),...
                '  CUR=''','R_phi*( -1/(ep0*kappa)*( ');
        if k==1
            fprintf(fid,'%s%s%s\n',...
                    strcat('(V(pz_',num2str(z2(1)),'_',num2str(z2(2)),'_',num2str(z2(3)),')'),...
                    '-0',')/(2*dz) )');
        elseif k==nz
            fprintf(fid,'%s%s%s\n',...
                    '(0-',...
                    strcat('V(pz_',num2str(z1(1)),'_',num2str(z1(2)),'_',num2str(z1(3)),')'),...
                    ')/(2*dz) )');
        else
            fprintf(fid,'%s%s%s\n',...
                    strcat('(V(pz_',num2str(z2(1)),'_',num2str(z2(2)),'_',num2str(z2(3)),')'),...
                    strcat('-V(pz_',num2str(z1(1)),'_',num2str(z1(2)),'_',num2str(z1(3)),')'),...
                    ')/(2*dz) )');
        end
        
        fprintf(fid,'+  ');

        if k == 1
            fprintf(fid,'%s%s%s%s\n',...
                    ' + (V(n1)+V(',...
                    strcat('phi_',num2str(z2(1)),'_',num2str(z2(2)),'_',num2str(z2(3))),...
                    '))/(dz*dz) )','''');
        elseif k == nz
        	fprintf(fid,'%s%s%s%s\n',...
                    ' + (V(',... 
                    strcat('phi_',num2str(z1(1)),'_',num2str(z1(2)),'_',num2str(z1(3))),...
                    ')+V(n2))/(dz*dz) )',''''...
                    );
        else
        	fprintf(fid,'%s%s%s%s%s\n',...
                    ' + (V(',... 
                    strcat('phi_',num2str(z1(1)),'_',num2str(z1(2)),'_',num2str(z1(3))),...
                    ')+V(',... 
                    strcat('phi_',num2str(z2(1)),'_',num2str(z2(2)),'_',num2str(z2(3))),...
                    '))/(dz*dz) )'''...
                    );
        end
            
            
        end
    end    
end


% print initial conditions
% n = 0;
% fprintf( fid,'\n\n%s','.IC  ' );
% for k = 1:nz-1
%     for j = 1:ny
%         for i = 1:nx
%             n = n+1;
%             fprintf( fid,'%s ',strcat('V(phi_',num2str(i),'_',num2str(j),'_',num2str(k),...
%                                       ')=''V0-',num2str(k),'*V0/',num2str(nz),'''') );
%            if mod(n,5)==0
%                 fprintf(fid,'\n%s','+  ');
%            end
%         end
%     end
% end



fprintf(fid,'\n\n%5s','.ENDS');
fclose(fid);

%type(strcat(dataname,'.cir'))