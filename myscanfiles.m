% close all
% a = dir('./day_color(small sample)/*.jpg');
% nf = size(a);
% 
% figure
% for i = 1:nf 
%     filename = horzcat(a(i).folder,'/',a(i).name);
%     I = imread(filename);
%     imshow(I);
%     drawnow
% end

im = imread('car1.jpg');
imgray = rgb2gray(im);
imbin = imbinarize(imgray);
imshow(imbin)

im = edge(imgray, 'prewitt');

Iprops=regionprops(im,'BoundingBox','Area', 'Image');
area = Iprops.Area;
count = numel(Iprops);
maxa= area;
boundingBox = Iprops.BoundingBox;
for i=1:count
   if maxa<Iprops(i).Area
      maxa=Iprops(i).Area;
      boundingBox=Iprops(i).BoundingBox;
   end
end   
% 
% im = imcrop(imbin, boundingBox);
% im = bwareaopen(~im, 500);
% [h, w] = size(im);
% 
% imshow(im);
% 
% Iprops=regionprops(im,'BoundingBox','Area', 'Image');
% count = numel(Iprops);
% noPlate=[];
% for i=1:count
%    ow = length(Iprops(i).Image(1,:));
%    oh = length(Iprops(i).Image(:,1));
%    if ow<(h/2) & oh>(h/3)
%        letter=Letter_detection(Iprops(i).Image);
%        noPlate=[noPlate letter]
%    end
% end
% 
% 
