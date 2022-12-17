%% Read image and convert it to black and white
window_size = 7;
% im = imread("day_color(small sample)/IMG_0383.jpg");
% imbw = movingAverages(im, window_size);

imagefiles = dir('*.jpg');     
nfiles = length(imagefiles);
for ii=1:nfiles
   currentfilename = imagefiles(ii).name;
   currentimage = imread(currentfilename);
   images{ii} = currentimage;
   images_bw{ii} = movingAverages(images{ii}, window_size);
end

%% Loop
digitsPlate = 6;
for i=1:nfiles
    im = images{i};
    imbw = images_bw{i};
    plates = getPlates(im, imbw);
    digits = getDigits(plates, digitsPlate);
    pause(5);
    close all;
end

%% Get plates from image
plates = getPlates(im, imbw);

%% Get digits from image
digitsPlate = 6;
digits = getDigits(plates, digitsPlate);

%% OCR


%% Functions
% Function to binarize image 
function imbw = movingAverages(im, window_size)
    imgray = rgb2gray(im);
    h = ones(window_size)/window_size^2;
    promig = imfilter(imgray, h, 'conv', 'replicate');
    imbw = imgray > (promig - 5);
end 

% Function to get plates from image
function subImages = getPlates(im, imbw)
    it = 0;
    subImages = {};
    imbw = imerode(imbw, strel('disk', 1));
    while numel(subImages) == 0 && it < 2
        Iprops = regionprops(imbw,'BoundingBox','Area', 'Image');
        numElems = numel(Iprops);
        [rows, cols] = size(im);
        area = rows*cols;
        for i=1:numElems
            h = Iprops(i).BoundingBox(4);
            w = Iprops(i).BoundingBox(3);
            whitePixels = Iprops(i).Image == 1; 
            whites = sum(Iprops(i).Image(whitePixels));
            npixels = numel(Iprops(i).Image);
            if Iprops(i).Area > area*0.0005 && Iprops(i).Area < area*0.02 && w > 2*h && w < 8*h && whites > npixels*0.25
                 figure, imshow(im)
                 hold on;
                 rectangle('Position', Iprops(i).BoundingBox, 'EdgeColor', 'g', 'LineWidth', 2)
                 subImages{numel(subImages)+1} = imcrop(im, Iprops(i).BoundingBox);
                 hold off;
            end
        end
        imbw = imerode(imbw, strel('disk', 1));
        it = it+1;
    end
end

% Function to get digits from plates
function digits = getDigits(plates, digitsPlate)
    digits = {};
    ee = strel('line', 2, 90);
    numImages = numel(plates);
    for i=1:numImages
        matricula = ~imbinarize(rgb2gray(plates{i}));
        original_matricula = matricula;
        matricula = imerode(matricula, ee);
        [h, w] = size(matricula);
        Iprops = regionprops(matricula, 'BoundingBox','Area', 'Image');
        numElems = numel(Iprops);
        if numElems < digitsPlate 
            continue
        end

        mean_width = 0;
        mean_height = 0;
        mean_gap = 0;

        for j=1:numElems

            h_bb = Iprops(j).BoundingBox(4);
            w_bb = Iprops(j).BoundingBox(3);
            x_bb = Iprops(j).BoundingBox(1);
            y_bb = Iprops(j).BoundingBox(2);

            if x_bb <= 1 || x_bb+w_bb >= w || y_bb <= 1 || y_bb+h_bb >= h
                continue
            end

            min_widht = w*0.01;
            max_widht = w*(1/7);
            min_height = 0.4*h;
            max_height = h;

            if h_bb <= max_height && h_bb >= min_height && w_bb <= max_widht && w_bb >= min_widht
                mean_width = mean_width + w_bb;
                mean_height = mean_height + h_bb;
                digits{numel(digits)+1} = Iprops(j).BoundingBox;
            end
        end

        mean_width = mean_width / numel(digits);
        mean_height = mean_height / numel(digits);

        % Check if we can fit a Bounding Box at the end
        if numel(digits) < digitsPlate && numel(digits) >= digitsPlate-1
            new_x = digits{1, numel(digits)}(1) + digits{1, numel(digits)}(3)*1.3;
            new_y = (digits{1, numel(digits)}(2) - digits{1, numel(digits)-1}(2)) + digits{1, numel(digits)}(2);
            if new_x + mean_width > 0  && new_x + mean_width < w && new_y + mean_height > 0 &&  new_y + mean_height < h
                new_bb = [new_x, new_y, mean_width, mean_height];
                overlapRatio = bboxOverlapRatio(new_bb, digits{1, numel(digits)});
                if overlapRatio == 0
                    digits{numel(digits)+1} = new_bb;
                end
            end
        end

        figure, imshow(original_matricula);
        hold on
        for k=1:numel(digits)
            rectangle('Position', digits{k}, 'EdgeColor', 'r', 'LineWidth', 2)
        end
        hold off
    end
end