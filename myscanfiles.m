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

im = imread('./car1.jpg');
imorig = im;
imgray = rgb2gray(im);

window_size = 31;
h = ones(window_size)/window_size^2;
promig = imfilter(imgray, h, 'conv', 'replicate');
%figure, imshow(promig), title('imatge promig');
imbw = imgray > (promig - 5);
%figure, imshow(imbw), title('Moving averages');

% imbin = imbinarize(imgray);
Iprops = regionprops(imbw,'BoundingBox','Area', 'Image');
count = numel(Iprops);

for i=1:count
    h = Iprops(i).BoundingBox(4);
    w = Iprops(i).BoundingBox(3);
    whitePixels = Iprops(i).Image == 1; 
    whites = sum(Iprops(i).Image(whitePixels));
    npixels = numel(Iprops(i).Image);
    if Iprops(i).Area > 1000 && Iprops(i).Area < 5000 && w > 2*h && whites > npixels*0.5
         figure, imshow(imorig)
         hold on;
         rectangle('Position', Iprops(i).BoundingBox, 'EdgeColor', 'g')
         hold off;
         %figure, imshow(Iprops(i).Image)
    end
end
