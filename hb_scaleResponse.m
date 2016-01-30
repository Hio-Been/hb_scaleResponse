function [resp, rt] = hb_scaleResponse(win,winRect,nLikertRange,customStim_mat)

% Usage Example;
%   [win, winRect] = Screen('OpenWindow', 0, [127 127 127], [0 0 500 500]);
%   [resp, rt] = hb_assessment(win,winRect,4);
%
% nLikertRange == 1 : Visual Analogue Scale (0~100%, continuous response)
% nLikertRange >= 2 : Likert Scale with n possible discrete responses
%
%% Algorithm Flow
% # 1. Basic setting (Screen initialize, and position of the stimuli)
%      * If window pointer is previously defined, skip this procedure
% # 2. Select assessment method (1: VAS, 2~ : Discrete Likert)
% # 3. Draw scale and tracking mouse position
% # 4. Calculate and return response
%
% Revision / Error Report >>> hiobeen@yonsei.ac.kr
% version 1.0.1, 2015-08-17

%% #1. Basic Setting & Ye-Oei Cheo-rhi
if nargin < 2
    Screen('Preference', 'SkipSyncTests', 2); GStreamer; AssertOpenGL; % Monitor option
    Screen('Preference', 'DefaultFontSize', 25);
    PsychDefaultSetup(2); KbName('UnifyKeyNames'); % Keyboard & Response option
    screenColor = [127 127 127];
    screenRect = [0 0 880 880];
    [win, winRect] = Screen('OpenWindow', 0, screenColor, screenRect);
else screenRect = winRect;
end; if nargin < 3
    nLikertRange = 1;
end; if nargin < 4
    % Custom Stimuli Properties
    customStim_mat = rand() * 255 * repmat(sin(linspace(-1,1,50).^.25), [150,5]);
end
customStim_texture = Screen('MakeTexture', win, customStim_mat);
customStim_size = size(customStim_mat);

scale_position = - floor(winRect(4) * .33); % Move vertically
text_position = - floor(winRect(4) * .4); % Below the Scale

% Scale Parameters
hori_bar_mat = 0 * ones([floor(winRect(4)*(.1/10)) floor(winRect(3)*(1/2))]);
hori_bar_texture = Screen('MakeTexture', win, hori_bar_mat);
hori_bar_size = size(hori_bar_mat);
vert_bar_mat = 0 * ones([floor(winRect(4)*(.25/10)) floor(winRect(3)*(1/300))]);
vert_bar_texture = Screen('MakeTexture', win, vert_bar_mat);
vert_bar_size = size(vert_bar_mat);

% Scale Markers Specification
ovalSize = 40; 
ovalWidth = 4; 
ovalColor = [0 0 255];

% Create mouse instance
import java.awt.Robot; mouse = Robot; 


%% #2. Assessment method
cp = [floor(winRect(3)*.5) floor(winRect(4)*.5)]; %Center point
hori_bar_pos = [floor(cp(1) - .5*hori_bar_size(2)),...
    floor(cp(2) - .5*hori_bar_size(1)) - scale_position,...
    floor(cp(1) + .5*hori_bar_size(2)),...
    floor(cp(2) + .5*hori_bar_size(1)) - scale_position];

if nLikertRange == 1
    nScaleColumns = 2;
else
    nScaleColumns = nLikertRange;
end

% Possible mouse positions and limit its movement
possibleMoveSpace = [     ...
    round(hori_bar_pos(1)+screenRect(1)),   ...
    round(.5 * (hori_bar_pos(2)+hori_bar_pos(4)) + screenRect(2)),   ...
    round(hori_bar_pos(3)+screenRect(1)),   ...
    round(.5 * (hori_bar_pos(2)+hori_bar_pos(4)) + screenRect(2) + 1)   ...
	%vert_bar_pos(4)+screen_size(2)   ...
    ];
initialMousePos = round(rand() * (possibleMoveSpace(3) - possibleMoveSpace(1)));
mouse.mouseMove(initialMousePos,(possibleMoveSpace(2)));


%% #3. Let's Get Response!
click = 0;
HideCursor;
t1 = GetSecs;
while ~click
    %% #3-1. Likert Bar Drawing
    % Hori bar draw
    Screen('DrawTexture', win, hori_bar_texture,...
        [0 0 hori_bar_size(2) hori_bar_size(1)], hori_bar_pos);
    % Vert bars draw
    xRange = linspace(hori_bar_pos(1),hori_bar_pos(3),nScaleColumns);
    for xPos = xRange
        vert_bar_pos = [ xPos - vert_bar_size(2),...
            mean([hori_bar_pos(2) hori_bar_pos(4)]) - (.5*vert_bar_size(1)),...
            xPos + vert_bar_size(2),...
            mean([hori_bar_pos(2) hori_bar_pos(4)]) + (.5*vert_bar_size(1)),...
            ];
        Screen('DrawTexture', win, vert_bar_texture,...
            [0 0 vert_bar_size(2) vert_bar_size(1)], vert_bar_pos);
    end
    
    
    %% #4. Get Response
    [cursorX, cursorY, clicks] = GetMouse;
    click = clicks(1);
    if cursorX < possibleMoveSpace(1); mouse.mouseMove(possibleMoveSpace(1), cursorY); cursorX = possibleMoveSpace(1);
    elseif cursorX > possibleMoveSpace(3); mouse.mouseMove(possibleMoveSpace(3), cursorY); cursorX = possibleMoveSpace(3);
    elseif cursorY < possibleMoveSpace(2); mouse.mouseMove(cursorX, possibleMoveSpace(2)); cursorY = possibleMoveSpace(2);
    elseif cursorY > possibleMoveSpace(4); mouse.mouseMove(cursorX, possibleMoveSpace(4)); cursorY = possibleMoveSpace(4);
    end
    
    
    if nLikertRange == 1 %VAS
        currentPoint = ( cursorX - possibleMoveSpace(1) ) / (possibleMoveSpace(3)-possibleMoveSpace(1));
        cvt2percent = currentPoint * 100;
        resp_for_show = (strcat([ num2str(cvt2percent) ' %' ]));
        xPos = cursorX - screenRect(1);
        yPos =  .5 * (vert_bar_pos(2)+vert_bar_pos(4)) + screenRect(2);
        Screen('FrameOval', win, ovalColor,...
            [ xPos-(ovalSize*.5), yPos - ovalSize*.5,...
            xPos+(ovalSize*.5), yPos + ovalSize*.5 ], ovalWidth);
        
        Screen('DrawText', win, resp_for_show, cp(1)+text_position, cp(2)-text_position);
        resp = cvt2percent;
        
    else % Likert
        respRange = linspace(possibleMoveSpace(1), possibleMoveSpace(3), nLikertRange);
        LetsFindNearestOne = abs(respRange - cursorX);
        [~,nearestIdx] = (min(LetsFindNearestOne));               

        for xPos = xRange(nearestIdx)
            yPos =  .5 * (vert_bar_pos(2)+vert_bar_pos(4)) + screenRect(2);
            Screen('FrameOval', win, ovalColor,...
                [ xPos-ovalSize*.5, yPos - ovalSize*.5,...
                xPos+ovalSize*.5, yPos + ovalSize*.5 ], ovalWidth);
        end
%         resp_for_show = (strcat([ 'Response : ' num2str(nearestIdx) ]));
        resp_for_show = (strcat([ '응답을 선택하세요' ]));
        Screen('DrawText', win, resp_for_show, cp(1)+text_position, cp(2)-text_position);
        resp = nearestIdx;
    end
    
    
    %% Add custom stimuli
    Screen('DrawTexture', win, customStim_texture, [0 0 customStim_size(2) customStim_size(1)],...
        [cp(1) - customStim_size(2)*.5, cp(2) - customStim_size(1)*.5 ...
        cp(1) + customStim_size(2)*.5, cp(2) + customStim_size(1)*.5] );
    if nargin < 4
    Screen('DrawText', win, 'Use Custom Image Matrix', cp(1) - customStim_size(2)*.6, cp(2) - customStim_size(1)*.75);
    end
    %% Flip it all
    Screen('Flip', win);
    
end
t2 = GetSecs;
rt = t2-t1;
ShowCursor;

return
