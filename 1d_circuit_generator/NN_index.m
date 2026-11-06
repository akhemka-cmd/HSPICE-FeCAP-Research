function [nn_idx] = NN_index(position,points,dimension)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
nn_idx=zeros(6,dimension);
nn_idx(1,:)=[position(1)-1, position(2), position(3)];
nn_idx(2,:)=[position(1)+1, position(2), position(3)];
nn_idx(3,:)=[position(1), position(2)-1, position(3)];
nn_idx(4,:)=[position(1), position(2)+1, position(3)];
nn_idx(5,:)=[position(1), position(2), position(3)-1];
nn_idx(6,:)=[position(1), position(2), position(3)+1];
end

