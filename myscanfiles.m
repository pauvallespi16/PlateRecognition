    
close all
a = dir('I:\vc\VC SP QT 2022\day_color(small sample)\*.jpg');
nf = size(a);
figure
for i = 1:nf 
filename = horzcat(a(i).folder,'/',a(i).name);
I = imread(filename);
imshow(I);
drawnow
end
