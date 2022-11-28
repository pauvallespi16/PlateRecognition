%% Read image and convert it to black and white
im = imread('./car2.jpg');
imbw = movingAverages(im);

%% Get plates from image
plates = getPlates(im, imbw);

%% Get digits from image
numsPlate = 7;
digits = getDigits(plates, numsPlate);

%% Functions
% Function to binarize image 
function imbw = movingAverages(im)
    window_size = 31;
    imgray = rgb2gray(im);
    h = ones(window_size)/window_size^2;
    promig = imfilter(imgray, h, 'conv', 'replicate');
    imbw = imgray > (promig - 5);
end 

% Function to get plates from image
function subImages = getPlates(im, imbw)
    subImages = {};
    Iprops = regionprops(imbw,'BoundingBox','Area', 'Image');
    numElems = numel(Iprops);
    for i=1:numElems
        h = Iprops(i).BoundingBox(4);
        w = Iprops(i).BoundingBox(3);
        whitePixels = Iprops(i).Image == 1; 
        whites = sum(Iprops(i).Image(whitePixels));
        npixels = numel(Iprops(i).Image);
        if Iprops(i).Area > 500 && Iprops(i).Area < 10000 && w > 2*h && whites > npixels*0.5
             figure, imshow(im)
             hold on;
             rectangle('Position', Iprops(i).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 2)
             subImages{numel(subImages)+1} = imcrop(im, Iprops(i).BoundingBox);
             hold off;
        end
    end
end

% Function to get digits from plates
function digits = getDigits(plates, numsPlate)
    digits = {};
    numImages = numel(plates);
    for i=1:numImages
        ee = strel('square', 1);
        matricula = ~imbinarize(rgb2gray(plates{i}));
        matricula = imopen(matricula, ee);
        Iprops = regionprops(matricula, 'BoundingBox','Area', 'Image');
        if numel(Iprops) < numsPlate 
            continue
        end
        matriculaOriginal = plates{i};
        numElems = numel(Iprops);
        for j=1:numElems
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
        rectangle('Position', digits{i}, 'EdgeColor', 'r', 'LineWidth', 2)
    end
    hold off
end