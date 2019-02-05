function [ MatrixData ] = SelectCoords( Nodedata,MatrixData  )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

n=1;
for i=1:size(MatrixData, 1);
    for j=n:size(Nodedata, 1);
        if Nodedata(j,1) == MatrixData(i,1);
            MatrixData(i,6)=Nodedata(j,2);
            MatrixData(i,7)=Nodedata(j,3);
            n=n+1;
            break
        end
    end
end

