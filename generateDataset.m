function generateDataset()
    if exist('letters_dataset', 'dir')
        rmdir('letters_dataset', 's');
    end
    if exist('digits_dataset', 'dir')
        rmdir('digits_dataset', 's');
    end
    mkdir('letters_dataset');
    mkdir('digits_dataset');

    % Load the binary image
    image = ~imbinarize(rgb2gray(imread('plates.png')));
    oldPlateImage = image(1:end/2, :);
    newPlateImage = image(end/2 + 1:end, :);
    figure, imshow(image);
    figure, imshow(oldPlateImage);
    figure, imshow(newPlateImage);
    
    storeSubImages(oldPlateImage, 'old');
    storeSubImages(newPlateImage, 'new');
    augmentDataset();

    if ~exist(fullfile('letters_dataset', 'O'), 'dir')
        mkdir(fullfile('letters_dataset', 'O'));
    end

    copyfile digits_dataset/0 letters_dataset/O;
end

function storeSubImages(image, txt)
    % Define the list of characters
    characters = '1234567890ABEHIKMNPTXYZ';
    
    % Label the connected components
    [labels, numLabels] = bwlabel(image);
    
    % Measure the properties of the connected components
    stats = regionprops(labels, 'BoundingBox', 'Area');
    
    % Iterate over the connected components
    character_idx = 1;
    for i = 1:numLabels
        if stats(i).Area > 800
            % Extract the pixel values of the current component
            boundingBox = stats(i).BoundingBox;
            digitImage = imcrop(image, boundingBox);

            folder = getFolderName(characters(character_idx));
            
             % Create a folder for the character if it doesn't already exist
            if ~exist(fullfile(folder), 'dir')
                mkdir(fullfile(folder));
            end

            digitImage = resizeImage(digitImage, 25, 30);
            
            % Save the image in the correct folder
            imwrite(digitImage, fullfile(folder, sprintf('%c_%s.png', ...
                characters(character_idx), txt)));

            character_idx = character_idx + 1;
        end
    end
end

function augmentDataset()
    % Define the list of characters
    characters = '1234567890ABEHIKMNPTXYZ';

    targetWidth = 25;
    targetHeight = 30;
    
    % Iterate over the characters
    for i = 1:length(characters)
        % Define the character folder
        characterFolder = getFolderName(characters(i));
        
        % Get the list of images in the character folder
        imageFiles = dir(fullfile(characterFolder, '*.png'));
        imageFiles = {imageFiles.name}';
        
        % Iterate over the images in the character folder
        for j = 1:length(imageFiles)
            % Load the image
            image = imread(fullfile(characterFolder, imageFiles{j}));
            % Define the number of augmented images to generate
            numAugmented = 40;
            
            % Iterate over the augmented images
            for k = 1:numAugmented
                % Rotate the image
                rotatedImage = imrotate(image, round(normrnd(0, 12))); %randi([-30 30]));
                
                % Scale the image
                scaledImage = imresize(rotatedImage, normrnd(1, 0.1));% randi([80 120])/100);
                
                % Translate the image
                translatedImage = imtranslate(scaledImage, [round(normrnd(0, 2.5)) round(normrnd(0, 2.5))]); % [randi([-5 5]) randi([-5 5])]);
                
                % Add noise to the image by flipping the values of random pixels
%                 numPixels = round(normrnd(5, 5)); % randi([0 15]);
%                 for l = 1:numPixels
%                     x = randi(size(translatedImage, 2));
%                     y = randi(size(translatedImage, 1));
%                     translatedImage(y, x) = ~translatedImage(y, x);
%                 end

                resizedImage = resizeImage(translatedImage, targetWidth, targetHeight);
                
                % Save the augmented image
                saveFolder = getFolderName(characters(i));
                imwrite(resizedImage, fullfile(saveFolder, sprintf('augmented_%d_%d.png', j, k)));
            end
        end
    end
end


function resizedImage = resizeImage(image, targetWidth, targetHeight)
    % Resize the image
    resizedImage = imresize(image, [targetHeight NaN], 'nearest');
    
    % Get the size of the resized image
    [height, width] = size(resizedImage);

    if width > targetWidth
        resizedImage = imresize(image, [NaN targetWidth], 'nearest');
        [height, width] = size(resizedImage);
        pad = targetHeight - height;
        resizedImage = padarray(resizedImage, [floor(pad/2) 0], 0, 'pre');
        resizedImage = padarray(resizedImage, [pad - floor(pad/2) 0], 0, 'post');
    else
        pad = targetWidth - width;
        resizedImage = padarray(resizedImage, [0 floor(pad/2)], 0, 'pre');
        resizedImage = padarray(resizedImage, [0 pad - floor(pad/2)], 0, 'post');
    end
end

function folder = getFolderName(char)
    if isstrprop(char, 'alpha')
        folder = fullfile('letters_dataset', char);
    else
        folder = fullfile('digits_dataset', char);
    end
end

