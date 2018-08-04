function find_edges (userData, meta)
%%%
% TODO:
% - discount "reliability" of runs near wake-up time, especially winter
% - select which rectangles are "HWS" (or at least grouped, using AIC)
% - if reliability high, coerce match_jump to select an existing run
% - Align rectangles.  How?
% - Confidence of rectangles.  How?
% - day-of-week
% - Adaptive: if "spike then flat" found in some runs, look for it elsewhere
%             if day-of-week found in some runs, look for it elsewhere
%             if overnight found in some runs, look for it elsewhere
%             if morning/afternoon operation found, look for it elsewhere
%             if miss one block, look for it in other blocks of the same day
% - fill gaps

% Terms:
%   run -- consecutive days with a given jump
%   reliability -- confidence that a run is from a timed device
%   rectangle -- consecutive days with a given turn-on and matching turn-off
%   quality/trust -- confidence that a rectangle is actually a timed device
%   quality -- confidence that the end of a rectangle is the true end?

% Columns in "runs"
% 1. start day  (first day of run)
% 2. stop day   (first day after run)
% 3. half-hour slot
% 4. half-hour slot, interpolated
% 5. jump (increase in power)
% 6. jump, as estimated from interpolated time
% 7. reliability
% 8. trend (average increase based on previous and subsequent slots)


  c = stripSpikes (squeeze(userData)');

  valid_days = find(~isnan(c(1,:)));
  cc = c (:,valid_days);

  if isempty(cc)
    return
  end

  % Try to guess when the pump is on.
  % Some pumps have two (or more?) powers, so record time and value

  [runs, d, dd, band] = runs_from_cc (cc, meta);

  % Merge runs oscillating between neighbouring times
  runs = merge_oscillating_runs (runs, cc, dd, band);

  % Merge adjacent runs if that seems suitable
  runs = merge_adjacent_runs(runs, cc, dd, band);
  
  show_runs (runs, c, valid_days);
end

function [runs, d, dd, band ] = runs_from_cc (cc, meta)
  % Extract time/start-day/end-day runs from 2-D array of jump sizes
  d1 = [0; diff(cc(:))];
  d1(1) = d1(1+meta.SamPerDay*(size (cc,2)>1));    % guess first jump
  d  = reshape (d1, size (cc));      % half-hour differences
          % create a band around midnight for identifying steps
  band = 2;
  dd = [d; d(1:2*band, :)];
  variance_by_hour = var (diff (cc'));
  med_lengths = [5, 7, 9, 11, 13, 15, 17, 19, 21];
  length_bins = min (1+floor (variance_by_hour*5), length (med_lengths));
  smoothed_c = zeros (size (cc));
  for i = 1:length (med_lengths)
    idx = (length_bins == i);
    smoothed_c(idx,:) = -rolling_min (-rolling_min (cc(idx,:)', med_lengths(i)), med_lengths(i))';
  end
  [~, times, jp] = find_jumps (smoothed_c, 0.05, 1);

  sp = sparse (mod (round (times),size (cc,1))+1, ...
               floor (round (times)/size (cc,1))+1, ...
               jp, ...
               size (smoothed_c,1), size (smoothed_c,2));
  sp = sparse (medfilt1 (full (sp),9,[],2));
  runs = runs_from_sparse (sp, dd, cc, band);
end

function show_runs (runs, c, valid_days)
 tmp = zeros(size(c));
 for j = 1:size(runs,1)
  if runs(j,3) ~= -1
   tmp(runs(j,3), valid_days(runs(j,1):runs(j,2)-1)) = runs(j,7)*sign(runs(j,5));
  end
 end
 figure(2); imagesc (tmp);
 figure(3); plot (c);
end

function [t, wgts, p3, jumps] = get_weighted_edge (time, data, power, g, offset, turn_on)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % A transition part way through an interval causes a mid-level power
  % Is floor(time) the mid point or end of the transition?
  if abs(time - round(time)) < 0.2
    mid = round(time) + [-1, 0];
  else        % time middle of the interval: floor(time) is the mid-point
    mid = floor(time);
  end
  if any(mid <= 0)
    mid = mid + size(data,1)/2;
  end

  % f
  wgts = zeros (length (mid), size (data, 2));
  for m = 1:length(mid)
    %transition = data(mid(m));
    after  = (mid(m)+1:   mid(m)+g);    % periods before and after.  Element 1
    before = (mid(m)-1:-1:mid(m)-g);    % is closest to the transition in both
    if before(end) <= 0
        before = before + size(data,1)/2;
    end

    if turn_on
      is_off = data(before,:);
      is_on  = data(after,:);
    else
      is_off = data (after,:);
      is_on  = data (before,:);
    end

    wgts(m,:) = 1 ./(offset + (is_off(1,:)) / power) ...
              + 0.5./(1 + (max(is_off, [], 1) - min(is_off, [], 1)) / power) ...
              + 0.5./(1 + (max(is_on,  [], 1) - min(is_on,  [], 1)) / power);
  end

  w = sum(wgts, 2);
  [~, mx] = max (w);  % pick time that looks most like a transition
  %w    = w   (mx);
  mid  = mid (mx);
  wgts = wgts(mx,:);

  p3    = wgts * [data(mid + 1,:)                     % after
                  data(mid - 1 + size(data,1)/2, :)   % before
                  data(mid,:)]';                      % middle
  frac = (p3(3) - p3(1)) / (p3(2) - p3(1));
  t = mid + max(0, min(1, frac));
  if t < 0.5
    t = t + size(data,1)/2;
  elseif t > size(data,1)/2 + 0.5
    t = t - size(data,1)/2;
  end
  if mid > 1
    jumps = data(mid+1,:) - data(mid-1,:);
  else
    jumps = data(mid+1,:) - data(mid-1+size(data,1)/2,[2:end, end]);
  end
end

function [score, ds] = not_ramp (time, on_off, days, cv)
 % Score from 1 if cv(time, days) looks like a two-part step,
 % to 0 if it looks like a linear change.
 % time is the nominal time of the step
 % on_off is 1 for turning on, -1 for turning off
 % days is the range of days that the step/ramp occurs
 % cv is either cv or cvw.

 % Turn time into a string of four half-hours,
 % starting from the "off" state and ending one step after the end of the
 % transition.
 time = floor (time * on_off) - 1;
 time = mod1 ((time:time+3) * on_off, size (cv, 1));
 low_to_high = cv(time, days);

 means = mean (low_to_high, 2);
 vars  = var  (low_to_high, 0, 2);

 mean_last_two = (vars(end-1) * means(end-1) + vars(end) * means(end)) ...
                 / (vars(end-1) + vars(end));
 badness1 = sum ((means(end-1:end) - mean_last_two) .^ 2 ./ vars(end-1:end)) / 2;

 % Least square linear regression
 sum_a   = sum (1 ./ vars);
 sum_ia  = sum ((1:length (vars)) ./ vars');
 sum_i2a = sum ((1:length (vars)).^2 ./ vars');
 sum_y   = sum (means ./vars);
 sum_iy  = sum ((1:length (vars))' .* means ./ vars);
  coeffs = [sum_a, sum_ia; sum_ia, sum_i2a] \ [sum_y; sum_iy];
 linear_fit = coeffs(1) + (1:length (vars))' * coeffs(2);

 badness2 = sum ((means - linear_fit) .^ 2 ./ vars) / 4;

 score = badness2 / (badness1 + badness2);
 
 ds = [1/badness1; 1; 1/badness2];
 ds = ds / sum (ds);
end

function [base, spikes] = stripSpikes(c, peakRatio)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if nargin < 2
      peakRatio = 5;
  end
  idx = find(c(2:end-1) - c(1:end-2) > peakRatio * abs(c(3:end) - c(1:end-2)));
  base = c;
  base(idx+1) = (c(idx) + c(idx+2))/2;
  if nargout > 1
    spikes = c -base;
  end
end

function [tm_real, jp, jp_real, reliability, trend] ...
                              = find_reliability(run, d, ~, samPerDay,band)
% (~ is 'c')
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  tm = run(3); st = run(1); en = run(2)-1;
  tt = mod1 (tm-band, samPerDay);
  slice = d(tt:tt+2*band, st:en);
  slice = slice(:, ~isnan(slice(1,:)));       % Ignore entirely-NaN days

  %jp = mean(slice(band+1,:));
  %sd = sqrt(var(slice(band+1,:) ));

  % Process a band around this run, to see if the jump is "significant"
  jp_all = mean(slice,2);
  sd_all = sqrt(var(slice,[],2));
  sd = sd_all(band+1);
  jp = jp_all(band+1);
  trend  = sum(jp_all - jp) / (2*band);

  % If jump is in the middle of the measurement slot, it affects two rows
  jp_all (sd_all > abs(jp_all)) = 0;  % ignore this row if jump < noise
  neighbours = jp_all([band, band+2]);        % one above / one below
  [~, better] = min(abs(jp - neighbours));
  jp_better = jp_all(better);
  if   sign(jp_better) == sign(jp) && ...
      (sign(jp_better) ~= sign(trend) || abs(jp_better) > 2*abs(trend)) && ...
      (jp_better+jp) ~= 0
    tm_real = tm + 2*(better-1.5) * (jp_better / (jp_better+jp));
    jp_real = jp + jp_better;
  else
    tm_real = tm;
    jp_real = jp;
  end

  reliability = abs(jp - trend) * sqrt(en-st) / (sd + 1e-12) ;
  if en-st < 5 && reliability > 14    % less than "significance" threshold,
    reliability = 14;               % but still may match a significant jump
  end
end

function [runs, runCount] = runs_from_sparse(sp, dd, c, band)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  runCount = 0;
  runs = zeros(2*size(c,1),3);
  % Find "runs": clusters of consecutive days with a jump at the same time
  for i = 1:size (c,1)
    d = diff(sp(i,:) ~= 0);
    swap = (sign(sp(i,1:end-1)) .* sign(sp(i,2:end)) == -1);
    if ~any(d)
      if (sp(i,1) ~= 0 && ~isnan(sp(i,1)))
        starts = 1;
        ends = size(c,2)+1;
      else
        continue
      end
    else
      starts1 = find(d>0 | swap) + 1;     % first day of run
      ends1   = find(d<0 | swap) + 1;     % first day after run
      if isempty(starts1)
        starts1 = 1;
      elseif isempty(ends1)
        ends1 = size(c,2) + 1;
      end
      if ends1(1) <= starts1(1)
        starts = [1, starts1];  % starts1 and ends1 to avoid Matlab warning
      else
        starts = starts1;
      end
      if length(starts) > length(ends1)
        ends = [ends1, size(c,2) + 1];
      else
        ends = ends1;
      end
      % Delete intervals that are all NaN
      if any(isnan(sp(i,:)))
        allNaN = zeros(size(starts));
        for j = 1:length(starts)
          if all(isnan(sp(i,starts(j)+1:ends(j))))
            allNaN(j) = 1;
          end
        end
        starts = starts(~allNaN);
        ends   = ends  (~allNaN);
      end
    end

    L = length(starts);
    if L > 0
      runs(runCount+(1:L),:) = [starts', ends', repmat(i,[L, 1])];
      runCount = runCount + L;
    end
  end
  runs = runs(1:runCount,:);  % truncate excess pre-allocated space

  % If any run is long, calculate "reliability" of all runs
  if max(runs(:,2) - runs(:,1)) > 14
    for i = 1:runCount
      [tm_real, jp, jp_real, reliability, trend] ...
              = find_reliability(runs(i,:), dd, c, size (c,1), band);
      runs(i,4:8) = [tm_real, jp, jp_real, reliability, trend];
    end
  else
    runs(:,4:8) = 0;        % if all short, skip that step
  end

  if runCount > 0
    runs = runs(~isnan(runs(:,7)),:);
    runCount = size(runs,1);
  else
    runs = zeros(0,8);    % Octave complains if 0x8 is compared with say 0x4
  end
end

function runs = merge_oscillating_runs (runs, cc, dd, band)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Merge runs oscillating between neighbouring times
  runCount = size(runs,1);
  toDelete = zeros(1,runCount);
  for i = 1:runCount
    if runs(i,3) < 0    % if already flagged for deletion
      continue
    end

    % Find runs that occur immediately after run i.
    if runs(i,2) < size(cc,2) + 1
      after1 = runs(:,1) == runs(i,2);
      after2 = after1;
      if runs(i,3) > 2
        after1 = after1 & (abs(runs(:,3)-runs(i,3))==1);
      end
      if runs(i,3) < size(cc,1) + 1
        after2 = after2 & (abs(runs(:,3)-runs(i,3))==1);
      end
      after = find (after1 | after2);
    else
      after = [];
    end

    rm = runs(i,7);
    rt = 0;
    rr = [];
    for k = 1:length(after)
      a = after(k);
      last = runs(a,2);
      aa = find(runs(:,3) == runs(i,3) & runs(:,1) == runs(a,2));
      if ~isempty(aa)
        if length(aa) > 1
          % Multiple overlapping "runs"
          % Merge with most reliable previous one
          [~, r] = max(runs(aa,7));
          aa = aa(r);
        end
        last = runs(aa,2);
      end

      run = [runs(i,1), last, runs(i,3)];
      [x1,x2,x3, r, x4] = find_reliability(run, dd, cc, size (cc,1),band);
      if r > rm && r > runs(a,7) && (isempty(aa) || r > runs(aa,7))
        rr = [a,aa];
        rt = runs(i,3);
        rm = r;
        x = [x1, x2, x3, x4];
      end

      run = [runs(i,1), runs(a,2), runs(a,3)];
      [x1,x2,x3, r, x4] = find_reliability(run, dd, cc, size (cc,1), band);
      if r > rm && r > runs(a,7)
        rr = a;
        rt = runs(a,3);
        rm = r;
        x = [x1, x2, x3, x4];
      end
    end

    if rm > runs(i,7)
      if rr(1) < i
        toDelete(i) = 1;
        runs(i,3) = -1;
        toExtend = rr(1);
      else
        toDelete(rr(1)) = 1;
        runs(rr(1),3) = -1;
        toExtend = i;
      end
      runs(toExtend,1) = runs(i,1);
      runs(toExtend,2) = runs(rr(end),2);
      runs(toExtend,3) = rt;
      runs(toExtend,4:8) = [x(1), x(2), x(3), rm, x(4)];
      if length(rr) > 1
        toDelete(rr(2)) = 1;
        runs(rr(2),3) = -1;
      end
    end
  end
  runs = runs(~toDelete,:);
end

function runs = merge_adjacent_runs(runs, cc, dd, band)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  [~, idx] = sort(runs(:,3) + runs(:,1)/size(cc,2));
  runs = runs(idx,:);
  if (size(runs,1) > 1)
    candidates = find(diff(runs(:,3)) == 0 & diff(sign(runs(:,5))) == 0 ...
                & (runs(1:end-1,7) > 10 | runs(2:end,7) > 10));
    for i = candidates(:)'
      st = runs(i,  2);
      en = runs(i+1,1);
      row= runs(i,  3);
      prev = mod1 (row-1, size(cc,1));
      if runs(i,5) < 0
        top = prev;
      else
        top = row;
      end
      if (all(cc(top, st:end) > max(runs(i:i+1,5))) && ...
           en - st < 0.2 * mean(runs(i:i+1,2) - runs(i:i+1,1)) && ...
           sign(mean(cc(row,st:end) - cc(prev,st:end))) == sign(runs(i,5)))
        run = [runs(i,1), runs(i+1,2), row];
        [x1,x2,x3,x4,x5] = find_reliability(run, dd, cc, size (cc,1), band);
        if x4 > runs(i,7)
              % merge into i+1, which is further checked next iter'n
          runs(i+1,1) = runs(i,1);
          runs(i+1,4:8) = [x1, x2, x3, x4, x5];
          runs(i,3) = -1;             % flag for deletion
        end
      end
    end
  end
  runs = runs(runs(:,3) ~= -1,:);   % delete runs flagged above for deletion
end

% Modulo, 1..modulus, not 0..modulus-1 (Matlab's arrays start from 1)
function m = mod1 (value, modulus)
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 % Modulo operator, returning values in [1, modulus], not [0, modulus-1].
  m = mod (value-1, modulus) + 1;
end
