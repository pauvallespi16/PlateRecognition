%% Read image and convert it to black and white
window_size = 7;
im = imread("day_color(small sample)/IMG_0472.jpg");
imbw = movingAverages(im, window_size);

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
            
            % If plate fulfills conditions: big and small enough, wide
            % enough and an amount of white pixels big enough
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
function real_digits = getDigits(plates, digitsPlate)
    real_digits = {};
    ee = strel('line', 1, 90);
    numImages = numel(plates);
    for i=1:numImages
        % Binarize image
        matricula = ~imbinarize(rgb2gray(plates{i}));
        matricula = imerode(matricula, ee);

        for it=1:3
            digits = {};
            
            Iprops = regionprops(matricula, 'BoundingBox','Area', 'Image');
            numElems = numel(Iprops);
            if numElems < digitsPlate 
                continue
            end
    
            mean_width = 0;
            mean_height = 0;
            [h, w] = size(matricula);
            h = uint8(h);
            w = uint8(w);
    
            for j=1:numElems
                x_bb = Iprops(j).BoundingBox(1);
                y_bb = Iprops(j).BoundingBox(2);
                w_bb = Iprops(j).BoundingBox(3);
                h_bb = Iprops(j).BoundingBox(4);
    
                % Check if digit is out of bounds
                if x_bb <= 1 || x_bb+w_bb >= w || y_bb <= 1 || y_bb+h_bb >= h
                    continue
                end
    
                min_width = w*0.01;
                max_width = w*(1/7);
                min_height = 0.4*h;
                max_height = h;
    
                % Check if size is valid
                if h_bb >= min_height && w_bb >= min_width && h_bb <= max_height
                    if w_bb <= max_width
                        digits{numel(digits)+1} = Iprops(j).BoundingBox;
                        mean_width = mean_width + w_bb;
                        mean_height = mean_height + h_bb;
                    % If the height is correct and the width is too big, it
                    % can be that there are 2 numbers stacked together
                    elseif w_bb < max_width*2.5
                        w_bb = 0.9*w_bb/2;
                        bbox1 = Iprops(j).BoundingBox;
                        bbox1(3) = w_bb;
                        
                        bbox2 = Iprops(j).BoundingBox;
                        bbox2(1) = bbox1(1)+w_bb*1.2;
                        bbox2(3) = w_bb;
                        digits{numel(digits)+1} = bbox1;
                        digits{numel(digits)+1} = bbox2;

                        mean_width = mean_width + w_bb;
                        mean_height = mean_height + Iprops(j).BoundingBox(2);
                    end
                end
            end

            if numel(digits) >= 4
                mean_width = mean_width / numel(digits);
                mean_height = mean_height / numel(digits);

                % Check if we can fit a Bounding Box at the end
                digits = lastDigitsFits(digits, w, h, mean_width, mean_height, digitsPlate);
        
                [max_x, max_y, min_x, min_y, first_y, last_y] = findMinMax(digits, w, h);
                real_digits = digits;
        
                % Remove the edges of the plate
                matricula(1:min_y-1, :) = 0;
                matricula(max_y+1:h, :) = 0;

                % Rotate the plate
                if it > 1
                    if min_x > 1
                        matricula(:, 1:min_x-1) = 0;
                    end
                    if max_x < w
                        matricula(:, max_x+1:w) = 0;
                    end
                else
                    % Use atan2 to get the angle between the two points
                    angle = rad2deg(atan2(double(last_y - first_y), double(max_x - min_x)));
                    matricula = imrotate(matricula, angle);
                end
            end    
        end

        % Remove overlaping digits
        real_digits = removeOverlaping(real_digits);

        % Print digits
        if numel(digits) >= 4
            printDigits(real_digits, matricula)
        end
    end
end

function [max_x, max_y, min_x, min_y, first_y, last_y] = findMinMax(digits, w, h)
    max_x = 1;
    max_y = 1;
    min_x = w;
    min_y = h;

    first_y = 0;
    last_y = 0;

    for j=1:numel(digits)
        if digits{1, j}(1) + digits{1, j}(3) > max_x
            last_y = digits{1, j}(2);
        end
        if digits{1, j}(1) < min_x
            first_y = digits{1, j}(2);
        end

        max_x = uint8(max(digits{1, j}(1) + digits{1, j}(3), max_x));
        max_y = uint8(max(digits{1, j}(2) + digits{1, j}(4), max_y));
        min_x = uint8(min(digits{1, j}(1), min_x));
        min_y = uint8(min(digits{1, j}(2), min_y));
    end
end

% Function to remove overlaping digits
function final_digits = removeOverlaping(digits)
    final_digits = {};
    
    % Loop through the list of bounding boxes
    for i = 1:numel(digits)
        % Get the current bounding box
        bbox1 = digits{1, i};
    
        % Initialize a flag to track whether the bounding box has been removed
        remove = false;
    
        % Loop through the remaining bounding boxes
        for j = (i+1):numel(digits)
            % Get the second bounding box
            bbox2 = digits{1, j};
            
            overlapRatio = bboxOverlapRatio(bbox1, bbox2);

            % If there is no overlap, skip to the next bounding box
            if overlapRatio == 0
                continue;
            end
    
            % If there is overlap, compare the areas of the bounding boxes
            % and keep the one with the larger area
            area1 = bbox1(3) * bbox1(4);
            area2 = bbox2(3) * bbox2(4);
            if area1 <= area2
                remove = true;
            end
        end
    
        % If the bounding box was not removed, add it to the final list
        if ~remove
            final_digits{numel(final_digits)+1} = bbox1;
        end
    end
end

function digits = lastDigitsFits(digits, w, h, mean_width, mean_height, digitsPlate)
    if numel(digits) < digitsPlate && numel(digits) >= digitsPlate-1
        new_x = digits{1, numel(digits)}(1) + digits{1, numel(digits)}(3)*1.3;
        new_y = (digits{1, numel(digits)}(2) - digits{1, numel(digits)-1}(2)) + digits{1, numel(digits)}(2);

        if new_x + mean_width > 0  && new_x + mean_width < w && new_y + mean_height > 0 &&  new_y + mean_height < h
            new_bb = [new_x, new_y, mean_width, mean_height];
            overlapRatio = bboxOverlapRatio(new_bb, digits{1, numel(digits)});
            % If there is no overlap
            if overlapRatio == 0
                digits{numel(digits)+1} = new_bb;
            end
        end
    end
end

function printDigits(digits, matricula)
    figure, imshow(matricula);
    hold on
    for k=1:numel(digits)
        rectangle('Position', digits{k}, 'EdgeColor', 'r', 'LineWidth', 2)
    end
    hold off
end

% Function to automate process
function automatedProcess()
    imagefiles = dir('*.jpg');     
    nfiles = length(imagefiles);
    for ii=1:nfiles
       currentfilename = imagefiles(ii).name;
       currentimage = imread(currentfilename);
       images{ii} = currentimage;
       images_bw{ii} = movingAverages(images{ii}, window_size);
    end
    
    digitsPlate = 6;
    for i=1:nfiles
        im = images{i};
        imbw = images_bw{i};
        plates = getPlates(im, imbw);
        digits = getDigits(plates, digitsPlate);
        w = waitforbuttonpress;
        axes;    
        close all;
    end
end