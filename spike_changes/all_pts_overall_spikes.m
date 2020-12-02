function all_pts_overall_spikes

%% Parameters
which_pts = [1 8 9 10];
pre_implant_idx = 50;
post_implant_idx = 51;
main_color = [0 0.4470 0.7410];
do_shade = 1;

%% Locations
locations = implant_files;
data_folder = [locations.main_folder,'data/data_files/'];
results_folder = [locations.main_folder,'results/'];
spike_folder = [results_folder,'spikes/'];
pwname = locations.pwfile;
addpath(genpath(locations.script_folder));
addpath(genpath(locations.ieeg_folder));
pt_file = 'pt_w_elecs.mat';

%% Load files
pt = load([data_folder,pt_file]);
pt = pt.pt;

%% Get counts for all the patients we can
if isempty(which_pts)
count = 0;
all_counts = [];
for p = 1:length(pt)
    try total_count = overall_spike_rate(p);
        count = count + 1;
        all_counts = [all_counts;total_count];
        which_pts = [which_pts,p];
    catch
        continue;
    end
end
else
    count = 0;
    all_counts = [];
    for p = which_pts
        try total_count = overall_spike_rate(p);
            count = count + 1;
            all_counts = [all_counts;total_count];
        catch
            continue;
        end
    end
end


%% Does implantation increase spike rates?
% Test to see if the immediate post-implant spike rate is higher than
% immediate pre-implant spike rate
% Signed rank test (very non normal distribution of spike rates)
if 0
    histogram([all_counts(:,pre_implant_idx);...
        all_counts(:,post_implant_idx)],20)
end

median_pre = median(all_counts(:,pre_implant_idx));
median_post = median(all_counts(:,post_implant_idx));
[pval,~,stats] = signrank(all_counts(:,post_implant_idx),all_counts(:,pre_implant_idx));
fprintf(['\nThe median spike count is %1.1f for pre-implantation and %1.1f for post implantation\n'...
    '(sign rank test p-value = %1.3f\n'],median_pre,median_post,pval);

num_inc = sum(all_counts(:,pre_implant_idx)<all_counts(:,post_implant_idx));
num_dec = sum(all_counts(:,pre_implant_idx)>all_counts(:,post_implant_idx));
fprintf('The spike rate increased post-reimplantation for %d patients and decreased for %d patients.\n',...
    num_inc,num_dec);

%% Plot counts

median_counts = median(all_counts,1);
iqr_counts = quantile(all_counts,[0.25,0.75],1);

figure
set(gcf,'position',[5 353 1163 377])
if do_shade
    
    shade_area_between_vectors(iqr_counts,main_color)
    hold on
    plot(median_counts,'linewidth',2,'color',main_color)
else
    
    errorbar(1:length(median_counts),median_counts,...
        median_counts - iqr_counts(1,:),iqr_counts(2,:)-median_counts,'o',...
        'linewidth',2,'markersize',10,'markerfacecolor',main_color)
    
end
hold on


ylabel('Spike counts')
xlabel('Time since original implantation')
set(gca,'fontsize',20)
rp = plot([50.5 50.5],get(gca,'ylim'),'linewidth',2);
legend(rp,'Re-implantation','fontsize',20)
print(gcf,[results_folder,'overall_spike_rate/all_pts'],'-depsc')
end