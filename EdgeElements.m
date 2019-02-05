function [EdgeElements] = EdgeElements(TopNodes, Elements)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

EdgeElements=zeros(round(3*sqrt(size(Elements, 1))), 1);
top=1;
i=1;
j=1;
for i=1:size(Elements,1);
   for j=1:size(TopNodes,1);
      for k=2:5;
        if Elements(i,k)==TopNodes(j,1);
        EdgeElements(top,1)=Elements(i,1);
        top=top+1;
        end
      end
   end
end


end

