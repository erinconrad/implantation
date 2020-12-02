function all_pts_increase

%% Parameters
which_pts = [1,8,9,10];
npts = length(which_pts);

%% Get stats for increase
% Initialize stats
t_stats = zeros(npts,1);
ps = zeros(npts,1);

for p = 1:npts
    [ps(p),t_stats(p)] = test_spike_increase(which_pts(p));
end

%% Are highest spike increase electrodes closer than expected by chance
[~,p] = ttest(t_stats);

end