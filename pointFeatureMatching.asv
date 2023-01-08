% Point feature matching
function pointFeatureMatching(matricula, bbox)
    % Get digit to recognize and add padding
    boxImage = imcrop(matricula, bbox);
    boxImage = padarray(boxImage, 50, 0, 'both');
    boxImage = padarray(boxImage', 50, 0, 'both')';
    targetSize = [200 NaN];
    boxImage = imresize(boxImage,targetSize);
    figure;
    imshow(boxImage);
    title('Image of a Box');

    % Get plate to compare the digit with
    sceneImage = ~imbinarize(rgb2gray(imread('plates.png')));
    figure;
    imshow(sceneImage);
    title('Image of a Cluttered Scene');
    
    % Detect Feature Points
    boxPoints = detectKAZEFeatures(boxImage);
    scenePoints = detectKAZEFeatures(sceneImage);
    
    figure;
    imshow(boxImage);
    title('100 Strongest Feature Points from Box Image');
    hold on;
    plot(selectStrongest(boxPoints, 100));

    figure;
    imshow(sceneImage);
    title('300 Strongest Feature Points from Scene Image');
    hold on;
    plot(selectStrongest(scenePoints, 300));


    % Extract Feature Descriptors
    [boxFeatures, boxPoints] = extractFeatures(boxImage, boxPoints);
    [sceneFeatures, scenePoints] = extractFeatures(sceneImage, scenePoints);

    % Find Putative Point Matches
    boxPairs = matchFeatures(boxFeatures, sceneFeatures);

    matchedBoxPoints = boxPoints(boxPairs(:, 1), :);
    matchedScenePoints = scenePoints(boxPairs(:, 2), :);
    figure;
    showMatchedFeatures(boxImage, sceneImage, matchedBoxPoints, ...
        matchedScenePoints, 'montage');
    title('Putatively Matched Points (Including Outliers)');
    
    % Locate the Object in the Scene Using Putative Matches
    [tform, inlierIdx] = estgeotform2d(matchedBoxPoints, matchedScenePoints, 'affine');
    inlierBoxPoints   = matchedBoxPoints(inlierIdx, :);
    inlierScenePoints = matchedScenePoints(inlierIdx, :);

    figure;
    showMatchedFeatures(boxImage, sceneImage, inlierBoxPoints, ...
        inlierScenePoints, 'montage');
    title('Matched Points (Inliers Only)');


    boxPolygon = [1, 1;...                           % top-left
        size(boxImage, 2), 1;...                 % top-right
        size(boxImage, 2), size(boxImage, 1);... % bottom-right
        1, size(boxImage, 1);...                 % bottom-left
        1, 1];                   % top-left again to close the polygon

    newBoxPolygon = transformPointsForward(tform, boxPolygon);

    figure;
    imshow(sceneImage);
    hold on;
    line(newBoxPolygon(:, 1), newBoxPolygon(:, 2), Color='y');
    title('Detected Box');
end
