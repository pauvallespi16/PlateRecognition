%% Read image and convert it to black and white
im = imread('./day_color(small sample)/IMG_0382.jpg');
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
    [rows, cols] = size(im);
    area = rows*cols;
    for i=1:numElems
        h = Iprops(i).BoundingBox(4);
        w = Iprops(i).BoundingBox(3);
        whitePixels = Iprops(i).Image == 1; 
        whites = sum(Iprops(i).Image(whitePixels));
        npixels = numel(Iprops(i).Image);
        if Iprops(i).Area > area*0.0001 && Iprops(i).Area < area*0.02 && w > 2*h && whites > npixels*0.5
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
    matriculaOriginal = {};
    for i=1:numImages
        ee = strel('square', 1);
        matricula = ~imbinarize(rgb2gray(plates{i}));
        matricula = imopen(matricula, ee);
        [h, w] = size(matricula);
        Iprops = regionprops(matricula, 'BoundingBox','Area', 'Image');
        if numel(Iprops) < numsPlate 
            continue
        end
        matriculaOriginal = plates{i};
        numElems = numel(Iprops);

        mean_width = 0;
        mean_height = 0;
        mean_gap = 0;

        for j=1:numElems
            h_bb = Iprops(j).BoundingBox(4);
            w_bb = Iprops(j).BoundingBox(3);

            min_widht = w*0.01;
            max_widht = w*(1/7);
            min_height = 0.4*h;
            max_height = h;

            if h_bb <= max_height && h_bb >= min_height && w_bb <= max_widht && w_bb >= min_widht
                mean_width = mean_width + w_bb;
                mean_height = mean_height + h_bb;
                mean_gap = mean_gap + Iprops(1).BoundingBox(2);

                digits{numel(digits)+1} = Iprops(j).BoundingBox;
            end
        end

        mean_width = mean_width / numel(digits);
        mean_height = mean_height / numel(digits);
        % mean_y = mean_y / numel(digits);

        % Check if we can fit a Bounding Box at the end
        if numel(digits) < numsPlate && numel(digits) >= numsPlate-1
            new_y = (digits{1, numel(digits)}(2) - digits{1, numel(digits)-1}(2)) + digits{1, numel(digits)}(2);
            new_bb = [digits{1, numel(digits)}(1)+mean_width*1.25, new_y, mean_width, mean_height];

            % Ratio of overlap between las digit and potential new digit
            overlapRatio = bboxOverlapRatio(new_bb, digits{1, numel(digits)});
            if overlapRatio == 0
                % digits{numel(digits)+1} = new_bb;
            end
        end

        figure, imshow(matricula);
        hold on
        for i=1:numel(digits)
            rectangle('Position', digits{i}, 'EdgeColor', 'r', 'LineWidth', 2)
        end
        hold off
    end
end