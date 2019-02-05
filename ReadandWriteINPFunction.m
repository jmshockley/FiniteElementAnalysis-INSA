%THIS FUNCTION WAS WRITTEN AS PART OF A PROJECT TO MODEL A UNIT CELL CONSISTING
%OF AN ALUMINUM MATRIX WITH A SINGLE AL2O3 REINFORCEMENT INSIDE.
%THE PURPOSE OF THE FUNCTION IS TO OPEN .INP FILES FROM ABAQUS, EXTRACT THE NODE AND
%ELEMENT COORDINATES, AND THEN USE THEM TO CREATE A NEW INPUT
%FILE WITH PERIODIC BOUNDARY CONDITIONS. I HAVE COMMENTED THE CODE TO THE
%BEST OF MY ABILITY.

%IN THE MODEL, ALL OF THE ALUMINUM MATRIX ELEMENTS ARE TYPE CPE4R (QUAD
%PLANE STRAIN) AND THE AL2O3 REINFORCEMENT ELEMENTS ARE TYPE CPE3 (TRI
%PLANE STRAIN). THIS KEEPS IT EASY TO DISTINGUISH THE TWO AND IS AN
%APPROPRIATE CHOICE GIVEN THE HIGH STIFFNESS OF AL2O3.

%Author: Dr. James Michael Shockley     james.shockley@mail.mcgill.ca
%October 2015
%LaMCoS, INSA-Lyon, France

%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------
%  _____           _     __ 
% |  __ \         | |   /_ |
% | |__) |_ _ _ __| |_   | |
% |  ___/ _` | '__| __|  | |
% | |  | (_| | |  | |_   | |
% |_|   \__,_|_|   \__|  |_|
%                           
%%PART 1: OPEN INP FILE FROM ABAQUS AND ACQUIRE ITS NODE AND ELEMENT COORDINATES
%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------

%THE FOLLOWING 3 LINES CAN BE ACTIVATED TO ENTER THE FILE NAME AND DESIRED SHEAR WITH
%PROMPTS TO DO SO. ALTERNATIVELY, DELETE THIS LINES, ADD "end" AFTER THE LAST LINE OF CODE AND REPLACE THE TOP
%LINE OF CODE WITH THIS: function [ ] = ReadandWriteINPFunction(fileToRead, maximumcompression,maximumshear)
fileToRead = input('Enter input file name without ".inp" filetype extension: ', 's');
maximumcompression=input('Enter desired displacement of top edge in compression: ');
maximumshear=input('Enter desired displacement of bottom edge in shear: ');

%OPEN FILE BASED ON SUPPLIED FILENAME
fileToRead1 = strcat(fileToRead, '.inp');
fileID=fopen(fileToRead1); %opening the file
n=1;

%FIND NODES IN INP FILE
while ~feof(fileID) %reading up to end of the file
tline = fgetl(fileID); %reading line by line
n=n+1;
if   strcmpi(tline, '*Node') %finding the line containing " Node Number"
    break    %stop reading if the "Node Number" was detected
end
end

%READ NODES IN INP FILE
formatSpec = '%f%f%f%*s%*s%*s%*s%[^\n\r]';
delimiter = ',';
%textscan(fileID, '%[^\n\r]', startRow, 'ReturnOnError', false);
dataArray = textscan(fileID, formatSpec, 'Delimiter', delimiter);
VarName1 = dataArray{:, 1};
VarName2 = dataArray{:, 2};
VarName3 = dataArray{:, 3};

Nodes=[VarName1 VarName2 VarName3];
disp('Done with nodes')


%FIND AND READ TRI AND QUAD ELEMENTS IN INP FILE. THE ORDER OF TRI VS. QUAD
%CAN BE CHANGED AS NECESSARY. ABAQUS DOES NOT SEEM TO BE CONSISTENT IN
%WHICH ONES COME FIRST.
%-----------------------------------
%TRI ELEMENTS

while ~feof(fileID) %reading up to end of the file
tline = fgetl(fileID); %reading line by line
n=n+1;
if   regexpi(tline, '\w*ELEMENT\w*') 
    break  
end
end

formatSpec2 = '%f%f%f%f%s%s%*s%*s%[^\n\r]';

dataArray2 = textscan(fileID, formatSpec2, 'Delimiter', delimiter);
EleName1 = dataArray2{:, 1};
EleName2 = dataArray2{:, 2};
EleName3 = dataArray2{:, 3};
EleName4 = dataArray2{:, 4};


Elementstri=[EleName1 EleName2 EleName3 EleName4];

clearvars EleName1 EleName2 EleName3 EleName4

%END OF TRI ELEMENTS
%----------------------------

%-----------------------------------
%QUAD ELEMENTS


while ~feof(fileID) %reading up to end of the file
tline = fgetl(fileID); %reading line by line
n=n+1;
if   regexpi(tline, '\w*ELEMENT\w*') %finding the line containing " Node Number"
    break    %stop reading if the "Node Number" was detected
end
end

formatSpec2 = '%f%f%f%f%f%s%s%*s%*s%[^\n\r]';

dataArray3 = textscan(fileID, formatSpec2, 'Delimiter', delimiter);
EleName1 = dataArray3{:, 1};
EleName2 = dataArray3{:, 2};
EleName3 = dataArray3{:, 3};
EleName4 = dataArray3{:, 4};
EleName5 = dataArray3{:, 5};

Elementsquad=[EleName1 EleName2 EleName3 EleName4 EleName5];
clearvars EleName1 EleName2 EleName3 EleName4 EleName5

%END OF QUAD ELEMENTS
%----------------------------

%CLOSE THE FILE

disp('Done with elements, *.inp file closed')
fclose(fileID);
clearvars filename delimiter startRow endRow formatSpec fileID ans tline dataArray VarName1 VarName2 VarName3 EleName1 EleName2 EleName3 EleName4 EleName5 dataArray2 fileToRead1 formatSpec2 n;
%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------
%  _____           _     ___  
% |  __ \         | |   |__ \ 
% | |__) |_ _ _ __| |_     ) |
% |  ___/ _` | '__| __|   / / 
% | |  | (_| | |  | |_   / /_ 
% |_|   \__,_|_|   \__| |____|
                             
%PART 2: PROCESS THE DATA FROM THE OLD INPUT FILE AND MAKE ALL THE
%NECESSARY CALCULATIONS FOR THE NEW INPUT FILE. THEN WRITE THE NEW INPUT
%FILE.
%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------



%FIND EDGE NODES: TOP, BOTTOM, LEFT, RIGHT

left=1;
right=1;
top=1;
bottom=1;

%FIRST FIGURE OUT WHAT THE EDGES ARE
    B=max(Nodes, [], 1);
    maxXnode=B(1,2);
    C=min(Nodes, [], 1);
    minXnode=C(1,2);
    clearvars B C;
    B=max(Nodes, [], 1);
    maxYnode=B(1,3);
    C=min(Nodes, [], 1);
    minYnode=C(1,3);
    clearvars B C;

%PREALLOCATION OF EDGE NODE MATRICES
LeftNodes=zeros(size(Nodes,1 ),4);
RightNodes=zeros(size(Nodes,1 ),4);
BottomNodes=zeros(size(Nodes,1 ),3);
TopNodes=zeros(size(Nodes, 1),3);

%GO THROUGH ENTIRE NODES MATRIX AND FIND THE EDGE NODES
for i=1:size(Nodes,1);
    if Nodes(i, 2) == minXnode;
        LeftNodes(left,1)=Nodes(i,1);
        LeftNodes(left,2)=Nodes(i,2);
        LeftNodes(left,3)=Nodes(i,3);
        left=left+1;
    end
    if Nodes(i, 2) == maxXnode;
        RightNodes(right,1)=Nodes(i,1);
        RightNodes(right,2)=Nodes(i,2);
        RightNodes(right,3)=Nodes(i,3);
        right=right+1;
    end
    if Nodes(i, 3) == maxYnode;
        TopNodes(top,1)=Nodes(i,1);
        TopNodes(top,2)=Nodes(i,2);
        TopNodes(top,3)=Nodes(i,3);
        top=top+1;
    end     
     if Nodes(i, 3) == minYnode;
        BottomNodes(bottom,1)=Nodes(i,1);
        BottomNodes(bottom,2)=Nodes(i,2);
        BottomNodes(bottom,3)=Nodes(i,3);
        bottom=bottom+1;
    end  
end




%ELIMINATE ROWS OF ZEROS IF THEY ACCIDENTALLY FIND THEIR WAY IN
LeftNodes(all(LeftNodes==0,2),:)=[];
RightNodes(all(RightNodes==0,2),:)=[];
TopNodes(all(TopNodes==0,2),:)=[];
BottomNodes(all(BottomNodes==0,2),:)=[];


%FIND THE TOP AND BOTTOM NODES WITHIN THE LEFTNODES AND RIGHTNODES SETS
    B=max(LeftNodes, [], 1);
    maxleftnode=B(1,3);
    C=min(LeftNodes, [], 1);
    minleftnode=C(1,3);
    clearvars B C;
    B=max(RightNodes, [], 1);
    maxrightnode=B(1,3);
    C=min(RightNodes, [], 1);
    minrightnode=C(1,3);
    clearvars B C;
    
    
disp('Done with edge nodes. Now determining edge elements.')

%left=1;
%right=1;
%top=1;
%bottom=1;

%CALL FUNCTION "EdgeElements" TO FIND THE EDGE ELEMENTS. NOT SURE WHY I
%LEFT THIS IN BECAUSE THEY NEVER GET USED BUT OH WELL
TopElements=EdgeElements(TopNodes, Elementsquad);
disp('top edge elements complete')
BottomElements=EdgeElements(BottomNodes, Elementsquad);
disp('bottom edge elements complete')
LeftElements=EdgeElements(LeftNodes, Elementsquad);
disp('left edge elements complete')
RightElements=EdgeElements(RightNodes, Elementsquad);
disp('right edge elements complete')

    
    
    
%THE FOLLOWING LINES SHOW WHAT THE FUNCTION "EdgeElements" DOES. IT IS MUCH MUCH FASTER AS A
%FUNCTION BUT IN CASE IT GETS LOST, THIS IS WHAT IT'S DOING
%LeftElements=zeros(round(3*sqrt(size(Elements, 1))), 1);
%RightElements=zeros(round(3*sqrt(size(Elements, 1))),1);
%BottomElements=zeros(round(3*sqrt(size(Elements, 1))),1);
%TopElements=zeros(round(3*sqrt(size(Elements, 1))),1);
%for i=1:size(Elements,1);
%   for j=1:size(TopNodes,1);
%      for k=2:5;
 %       if Elements(i,k)==TopNodes(j,1);
%        TopElements(top,1)=Elements(i,1);
%        top=top+1;
%        end
%      end
%   end
%end

%for i=1:size(Elements,1);
%   for j=1:size(BottomNodes,1);
%      for k=2:5;
%        if Elements(i,k)==BottomNodes(j,1);
%        BottomElements(bottom,1)=Elements(i,1);
%        bottom=bottom+1;
%        end
 %     end
 %  end
%end
%disp('bottom elements complete')
%for i=1:size(Elements,1);
%   for j=1:size(LeftNodes,1);
%      for k=2:5;
%       if Elements(i,k)==LeftNodes(j,1);
%       LeftElements(left,1)=Elements(i,1);
%        left=left+1;
%        end
 %     end
 %  end
%end
%disp('left elements complete')
%%for i=1:size(Elements,1);
 %  for j=1:size(RightNodes,1);
 %     for k=2:5;
 %       if Elements(i,k)==RightNodes(j,1);
   %     RightElements(right,1)=Elements(i,1);
   %     right=right+1;
%        end
%      end
 %  end
%end
%disp('right elements complete')

%REMOVE LINES OF ZEROS
LeftElements(all(LeftElements==0,2),:)=[];
RightElements(all(RightElements==0,2),:)=[];
TopElements(all(TopElements==0,2),:)=[];
BottomElements(all(BottomElements==0,2),:)=[];

%REMOVE DUPLICATES
TopElementsUnique=unique(TopElements);
BottomElementsUnique=unique(BottomElements);
RightElementsUnique=unique(RightElements);
LeftElementsUnique=unique(LeftElements);

%PUT THEM IN ORDER
LeftNodessort=sortrows(LeftNodes,3);
RightNodessort=sortrows(RightNodes,3);
RightNodes=RightNodessort;
LeftNodes=LeftNodessort;

%TEST TO DETERMINE IF PERIODICITY IS POSSIBLE
if size(LeftElementsUnique, 1)==size(RightElementsUnique,1);
   disp('Left and right sides are symmetrical. Periodicity conditions are possible')
else
    disp('WARNING: Periodicity conditions NOT possible')
end
disp('Done with edge elements. Now writing new .inp file.')
%clearvars left right top bottom i j k TopElements BottomElements LeftElements RightElements TopNodessize RightNodessort LeftNodessort;

%-----------------------------------
%-----------------------------------
            
%CORRECT THE AMOUNT OF SHEAR DISPLACEMENT FOR THE FACT THAT SHEAR STRAIN IS
%A FUNCTION OF HEIGHT. THIS KEEPS THE SHEAR STRAIN FROM A SELECTED DEGREE OF
%SHEAR DISPLACEMENT CONSTANT REGARDSLESS OF THE SELECTED DEGREE OF COMPRESSION.
maximumshearstrain=maximumshear*(maxYnode-minYnode-maximumcompression)/(maxYnode-minYnode);

%CALCULATE THE AMOUNT THAT EACH EDGE NODE NEEDS TO BE DISPLACED TO KEEP IT
%IN A LINE
for i=1:size(LeftNodes,1);
        LeftNodes(i,4)=maximumshearstrain*(1-(LeftNodes(i,3)-minleftnode)/(maxleftnode-minleftnode));
end
for i=1:size(RightNodes,1);
        RightNodes(i,4)=maximumshearstrain*(1-(RightNodes(i,3)-minrightnode)/(maxrightnode-minrightnode));
end


%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------
%  _____           _     ____  
% |  __ \         | |   |___ \ 
% | |__) |_ _ _ __| |_    __) |
% |  ___/ _` | '__| __|  |__ < 
% | |  | (_| | |  | |_   ___) |
% |_|   \__,_|_|   \__| |____/ 
%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------
%PART 3: WRITE THE NEW INPUT FILE LINE BY LINE



%FILENAME STUFF
%Filename = input('File name?', 's');
Filenametot = strcat(fileToRead, '-periodicity');
Filenametotal = strcat(Filenametot,'_Comp_%.0f_Shear_%.0f', '.inp');
Filenametotalstring=sprintf(Filenametotal, 10*maximumcompression,10*maximumshear);
fid=fopen(Filenametotalstring,'w');


%START WRITING
fprintf(fid,'*HEADING\n');

fprintf(fid,'*NODE\n');

for i=1:size(Nodes, 1);
fprintf(fid,'%.0f,%.9f,%.9f\n', Nodes(i,:));
end
fprintf(fid,'**REFERENCE NODE FOR LEFT AND THEN RIGHT VERTICAL\n');
B=size(Nodes,1)+1;
fprintf(fid,'%.0f,%f,%f\n', B, minXnode , 35);
B=B+1;
fprintf(fid,'%.0f,%f,%f\n', B, maxXnode , 35);
B=B+1;
Numberoffirstdummynode=B;

for i=1:2*size(LeftNodes, 1);

fprintf(fid,'**DUMMY NODE%.0f\n', B);
fprintf(fid,'%.0f,%f,%f\n', B, 45, 45);
B=B+1;
end

fprintf(fid,'*ELEMENT, TYPE=CPE3\n');

for i=1:size(Elementstri, 1);
fprintf(fid,'%.0f,%.0f,%.0f,%.0f\n', Elementstri(i,:));
end

fprintf(fid,'*ELEMENT, TYPE=CPE4R\n');

for i=1:size(Elementsquad, 1);
fprintf(fid,'%.0f,%.0f,%.0f,%.0f,%.0f\n', Elementsquad(i,:));
end

fprintf(fid,'*ELSET, ELSET=REINFORCEMENT-SET, GENERATE\n');
fprintf(fid,'%.0f,%.0f,%.0f\n', Elementstri(1,1), Elementstri(size(Elementstri,1), 1), 1);

fprintf(fid,'*ELSET, ELSET=MATRIX-SET, GENERATE\n');
fprintf(fid,'%.0f,%.0f,%.0f\n', Elementsquad(1,1), Elementsquad(size(Elementsquad,1), 1), 1);

fprintf(fid,'*NSET, NSET=TOPNSET\n');
fprintf(fid,'%.0f,\n', TopNodes(:,1));

fprintf(fid,'*ELSET, ELSET=TOPELSET\n');
fprintf(fid,'%.0f,\n', TopElementsUnique(:,1));

fprintf(fid,'*NSET, NSET=BOTNSET\n');
fprintf(fid,'%.0f,\n', BottomNodes(:,1));

fprintf(fid,'*ELSET, ELSET=BOTELSET\n');
fprintf(fid,'%.0f,\n', BottomElementsUnique(:,1));

fprintf(fid,'*NSET, NSET=LEFTREFPT\n');
fprintf(fid,'%.0f,\n', Nodes(size(Nodes, 1),1)+1);

fprintf(fid,'*NSET, NSET=RIGHTREFPT\n');
fprintf(fid,'%.0f,\n', Nodes(size(Nodes, 1),1)+2);

fprintf(fid,'*NSET, NSET=BOTHREFPTS\n');
fprintf(fid,'%.0f,%.0f\n', Nodes(size(Nodes, 1),1)+1, Nodes(size(Nodes, 1),1)+2);

fprintf(fid,'*NSET, NSET=LEFTNSET\n');
fprintf(fid,'%.0f,\n', LeftNodes(:,1));

fprintf(fid,'*ELSET, ELSET=LEFTELSET\n');
fprintf(fid,'%.0f,\n', LeftElementsUnique(:,1));

fprintf(fid,'*NSET, NSET=RIGHTNSET\n');
fprintf(fid,'%.0f,\n', RightNodes(:,1));

fprintf(fid,'*ELSET, ELSET=RIGHTELSET\n');
fprintf(fid,'%.0f,\n', RightElementsUnique(:,1));

for i=1:size(LeftNodes, 1);
    fprintf(fid,'*NSET, NSET=LEFTNODE%.0f\n', LeftNodes(i,1));
    fprintf(fid,'%.0f\n', LeftNodes(i,1));
end

for i=1:size(RightNodes, 1);
    fprintf(fid,'*NSET, NSET=RIGHTNODE%.0f\n', RightNodes(i,1));
    fprintf(fid,'%.0f\n', RightNodes(i,1));
end

for i=1:2*size(LeftNodes, 1);
fprintf(fid,'*NSET, NSET=DUMMYNODE%.0f\n', i+Numberoffirstdummynode-1); 
fprintf(fid,'%.0f,\n', i+Numberoffirstdummynode-1);
end

fprintf(fid,'*NSET, NSET=DUMMYNODESET1\n'); 
for i=1:size(LeftNodes,1);
    fprintf(fid,'DUMMYNODE%.0f,\n', i+Numberoffirstdummynode-1);
end

fprintf(fid,'*NSET, NSET=DUMMYNODESET2\n'); 
for i=1:size(LeftNodes,1);
    fprintf(fid,'DUMMYNODE%.0f,\n', i+Numberoffirstdummynode-1+size(LeftNodes,1));
end

fprintf(fid,'*SURFACE, NAME=S_SURF-LEFT, TRIM=NO\n');
fprintf(fid,'LEFTELSET\n');

fprintf(fid,'*SURFACE, NAME=S_SURF-RIGHT, TRIM=NO\n');
fprintf(fid,'RIGHTELSET\n');



fprintf(fid,'*SOLID SECTION, ELSET=REINFORCEMENT-SET, MATERIAL=AL2O3\n');
fprintf(fid,'*MATERIAL, NAME=AL2O3\n');
fprintf(fid,'*ELASTIC\n');
fprintf(fid,'300., 0.2\n');
fprintf(fid,'*DENSITY\n');
fprintf(fid,'4.1,\n');
fprintf(fid,'*SOLID SECTION, ELSET=MATRIX-SET, MATERIAL=AL\n');
fprintf(fid,'*MATERIAL, NAME=AL\n');
fprintf(fid,'*ELASTIC\n');
fprintf(fid,'69., 0.33\n');
fprintf(fid,'*PLASTIC\n');
fprintf(fid,'0.2, 0.\n');
fprintf(fid,'0.246, 0.0237\n');

fprintf(fid,'*DENSITY\n');
fprintf(fid,'2.7,\n');

fprintf(fid,'*Surface, type=SEGMENTS, name=m_Surf-left\n');
fprintf(fid,'START,           -30.,         35.\n');
fprintf(fid,' LINE,           -30.,         -35.\n');

fprintf(fid,'*Rigid Body, ref node=LEFTREFPT, analytical surface=m_Surf-left\n');
fprintf(fid,'*Surface, type=SEGMENTS, name=m_Surf-right\n');

fprintf(fid,'START,           30.,         -35.\n');
fprintf(fid,' LINE,           30.,          35.\n');
fprintf(fid,'*Rigid Body, ref node=RIGHTREFPT, analytical surface=m_Surf-right\n');

fprintf(fid,'*Surface Interaction, name=IntProp-sansfriction\n');
fprintf(fid,'1.,\n');
fprintf(fid,'*Friction\n');
fprintf(fid,'0.,\n');
fprintf(fid,'*Surface Behavior, no separation, pressure-overclosure=HARD\n');
fprintf(fid,'*Contact Pair, interaction=IntProp-sansfriction, type=SURFACE TO SURFACE\n');
fprintf(fid,'S_SURF-LEFT, m_Surf-left\n');
fprintf(fid,'*Contact Pair, interaction=IntProp-sansfriction, type=SURFACE TO SURFACE\n');
fprintf(fid,'S_SURF-RIGHT, m_Surf-right\n');

%for i=1:size(LeftNodes,1);
%    
%    fprintf(fid,'*Equation\n');
%    fprintf(fid,'3\n');
%    fprintf(fid,'LEFTNODE%.0f,1,1, RIGHTNODE%.0f,1,-1, DUMMYNODE%.0f,1,-1\n', LeftNodes(i,1), RightNodes(i,1), i+Numberoffirstdummynode-1);
%    
%end

%for i=1:size(LeftNodes,1);
 %   
%    fprintf(fid,'*Equation\n');
%    fprintf(fid,'3\n');
%    fprintf(fid,'LEFTNODE%.0f,2,1, RIGHTNODE%.0f,2,-1, DUMMYNODE%.0f,2,-1\n', LeftNodes(i,1), RightNodes(i,1), i+size(LeftNodes,1)+Numberoffirstdummynode-1);
%    
%end

%USING THE DUMMY NODES, AN EQUATION IS CONSTRUCTED SO THAT THE DEGREES OF
%FREEDOM 1 AND 2 ON EACH PAIR OF LEFT AND RIGHT NODES SUM TO ZERO. THIS
%EQUATION CONSTRAINT ALLOWS FOR THE DUMMY NODE TO EITHER MOVE FREE, AND
%HENCE THE LEFT AND RIGHT NODES CAN DO WHAT THEY WANT, OR BE FIXED AND
%FORCE THE LEFT AND RIGHT NODES TO FOLLOW THE SAME MOTION.

%THIS PURPOSELY EXCLUDES THE TOP AND BOTTOM NODES BECAUSE OTHERWISE,
%PUTTING MULTIPLE BOUNDARY CONDITIONS ON THE SAME NODES WILL CAUSE ERRORS.
for i=2:size(LeftNodes,1)-1;
    
    fprintf(fid,'*Equation\n');
    fprintf(fid,'3\n');
    fprintf(fid,'LEFTNODE%.0f,1,1, RIGHTNODE%.0f,1,-1, %.0f,1,-1\n', LeftNodes(i,1), RightNodes(i,1), i+Numberoffirstdummynode-1);
    
end

for i=2:size(LeftNodes,1)-1;
    
    fprintf(fid,'*Equation\n');
    fprintf(fid,'3\n');
    fprintf(fid,'LEFTNODE%.0f,2,1, RIGHTNODE%.0f,2,-1, %.0f,2,-1\n', LeftNodes(i,1), RightNodes(i,1), i+size(LeftNodes,1)+Numberoffirstdummynode-1);
    
end

%STEP ONE: COMPRESSION

fprintf(fid,'*STEP, NLGEOM=YES\n');
fprintf(fid,'*STATIC\n');
fprintf(fid,'0.01, 1., 1e-05, 1.\n');
fprintf(fid,'*BOUNDARY\n');
fprintf(fid,'TOPNSET, 2,2, -%.1f\n', maximumcompression);
fprintf(fid,'BOTHREFPTS, 2,2,\n');
fprintf(fid,'*BOUNDARY, type=VELOCITY\n');
fprintf(fid,'BOTNSET, 2,2, \n');
fprintf(fid,'*OUTPUT, FIELD, VARIABLE=PRESELECT\n');
fprintf(fid,'*OUTPUT, HISTORY\n');
fprintf(fid,'*ENERGY PRINT\n');
fprintf(fid,'*END STEP\n');

%STEP TWO: SHEAR

fprintf(fid,'*STEP\n');
fprintf(fid,'*STATIC\n');
fprintf(fid,'0.01, 1., 1e-05, 1.\n');

fprintf(fid,'*MODEL CHANGE, TYPE=CONTACT PAIR, REMOVE\n');
fprintf(fid,'S_SURF-LEFT, m_Surf-left\n');
fprintf(fid,'*MODEL CHANGE, TYPE=CONTACT PAIR, REMOVE\n');
fprintf(fid,'S_SURF-RIGHT, m_Surf-right\n');


fprintf(fid,'*Boundary, type=VELOCITY\n');
fprintf(fid,'BOTNSET, 1, ,%f\n', maximumshearstrain);
fprintf(fid,'TOPNSET, 1, , 0.\n');
fprintf(fid,'TOPNSET, 2, , 0.\n');
fprintf(fid,'DUMMYNODESET1, 1, , 0.\n');
fprintf(fid,'DUMMYNODESET2, 2, , 0.\n');
for i=2:size(LeftNodes, 1)-1;
fprintf(fid,'LEFTNODE%.0f, 1, ,%f\n', LeftNodes(i,1), LeftNodes(i,4));
end
%THIS MAKES SURE THE STRESS, STRAIN, AND NODAL DISPLACEMENTS ARE OUTPUT IN THE
%.DAT FILE WHICH CAN BE BE OPENED AND ANALYZED USING ANOTHER MATLAB SCRIPT. OTHERWISE THE
%.DAT FILE COULD BE DIRECTLY OPENED AND THE DATA COPIED OUT OF IT. FREQUENCY 999 FORCES ONLY
%THE FINAL INCREMENT OF THE STEP TO BE OUTPUT.
fprintf(fid,'*NODE PRINT, FREQUENCY=999\n');
fprintf(fid,'COORD\n');

fprintf(fid,'*EL PRINT, POSITION=AVERAGED AT NODES, FREQUENCY=999\n');
fprintf(fid,'S\n');

fprintf(fid,'*OUTPUT, FIELD, VARIABLE=PRESELECT, FREQUENCY=999\n');
fprintf(fid,'*ELEMENT OUTPUT\n');
fprintf(fid,'S\n');
fprintf(fid,'*OUTPUT, HISTORY\n');
fprintf(fid,'*ENERGY PRINT\n');
fprintf(fid,'*END STEP\n');

fclose(fid);

%INP FILE IS WRITTEN
                              

%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------
%  _____           _     _  _      __           _   _                   ___  
% |  __ \         | |   | || |    / /          | | (_)                 | \ \ 
% | |__) |_ _ _ __| |_  | || |_  | | ___  _ __ | |_ _  ___  _ __   __ _| || |
% |  ___/ _` | '__| __| |__   _| | |/ _ \| '_ \| __| |/ _ \| '_ \ / _` | || |
% | |  | (_| | |  | |_     | |   | | (_) | |_) | |_| | (_) | | | | (_| | || |
% |_|   \__,_|_|   \__|    |_|   | |\___/| .__/ \__|_|\___/|_| |_|\__,_|_|| |
%-----------------------------------
%-----------------------------------
%-----------------------------------
%-----------------------------------
%%PART 4: WRITE A LAUNCHER FILE FOR THE LAMCOS COMPUTATIONAL CLUSTER


disp('Now writing launcher file.')
clearvars fid


formatSpeclauncher=strcat('launcher_', Filenametot, '_Comp_%.0f_Shear_%.0f.txt');

launcherfilename = sprintf(formatSpeclauncher,10*maximumcompression,10*maximumshear);

fid=fopen(launcherfilename,'w');
fprintf(fid,'#!/bin/bash\n');
fprintf(fid,'#PBS -l nodes=1:ppn=4:compute,walltime=24:00:00,mem=2gb\n\n');
A=strcat('#PBS -N JMS-', Filenametot, '_Comp_%.0f_Shear_%.0f\n');
fprintf(fid,A,10*maximumcompression,10*maximumshear);
fprintf(fid,'#PBS -j oe\n\n');
fprintf(fid,'# Receive email at begining and end of job :\n');
fprintf(fid,'#PBS -M james-michael.shockley@insa-lyon.fr\n\n');
fprintf(fid,'#PBS -m abe\n\n');
fprintf(fid,'# Set Intel compilers for user subroutines\n');
fprintf(fid,'module load intel/11.1.080\n');
fprintf(fid,'# Load Abaqus module to define executable path\n');
fprintf(fid,'module load abaqus/6.11.2\n');
fprintf(fid,'cd $PBS_O_WORKDIR\n');
B=strcat('INPNAME=', Filenametot, '_Comp_%.0f_Shear_%.0f', '\n');
fprintf(fid,B,10*maximumcompression,10*maximumshear);
C=strcat('JOBNAME=JMS-', Filenametot, '_Comp_%.0f_Shear_%.0f', '\n');
fprintf(fid,C,10*maximumcompression,10*maximumshear);
fprintf(fid,'abaqus input=$INPNAME.inp job=$JOBNAME cpus=${PBS_NP} interactive\n');

fclose(fid);
clearvars fid
disp('Script Complete.')







%-----------------------------------
%-----------------------------------
