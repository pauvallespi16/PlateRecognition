im = imread('./day_color(small sample)/IMG_0414.jpg');
imorig = im;
imgray = rgb2gray(im);

window_size = 31;
h = ones(window_size)/window_size^2;
promig = imfilter(imgray, h, 'conv', 'replicate');
imbw = imgray > (promig - 5);

Iprops = regionprops(imbw,'BoundingBox','Area', 'Image');
count = numel(Iprops);
subImages = {};

for i=1:count
    h = Iprops(i).BoundingBox(4);
    w = Iprops(i).BoundingBox(3);
    whitePixels = Iprops(i).Image == 1; 
    whites = sum(Iprops(i).Image(whitePixels));
    npixels = numel(Iprops(i).Image);
    if Iprops(i).Area > 500 && Iprops(i).Area < 10000 && w > 2*h && whites > npixels*0.5
         figure, imshow(imorig)
         hold on;
         rectangle('Position', Iprops(i).BoundingBox, 'EdgeColor', 'g')
         subImages{numel(subImages)+1} = imcrop(imorig, Iprops(i).BoundingBox);
         hold off;
    end
end

%%
numsMatricula = 7;
digits = {};
for i=1:numel(subImages)
    ee = strel('square', 1);
    matricula = ~imbinarize(rgb2gray(subImages{i}));
    matricula = imopen(matricula, ee);
    Iprops = regionprops(matricula, 'BoundingBox','Area', 'Image');
    if numel(Iprops) < numsMatricula 
        continue
    end
    matriculaOriginal = subImages{i};
    for j=1:numel(Iprops)
        h = Iprops(j).BoundingBox(4);
        w = Iprops(j).BoundingBox(3);
          
        if Iprops(j).Area > 50 && Iprops(j).Area < 2000 && w < h
             digits{numel(digits)+1} = Iprops(j).BoundingBox;
        end
    end
end

figure, imshow(matriculaOriginal);
hold on
for i=1:numel(digits)
    rectangle('Position', digits{i}, 'EdgeColor', 'r')
end
hold off