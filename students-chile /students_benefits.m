%% Intro
% Este código genera las figuras de la estimación de beneficios para la
% nota de costos de la implementación de Sistemas de Asignación
% Centralizada Digital.

%% Set Paths
username = 'antoniaaguilera';
if strcmp(username,'antoniaaguilera')
    Path = '/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/students/';
    dataPath = [Path 'data/'];
    figuresPath = [ Path 'figures/'];
else
    error('Get your paths straight!')
end

%% Set Colors
c = parula(63);
sz = 10 ;
color1 = "#5627FF";
color2 = "#2AC2B2" ;
color3 = "#9A7DFF" ;
color4 = "#72E8CE" ;

%% Benefits:



%% Call Data
benefit1 = xlsread([ dataPath 'output/forbenefits1.xlsx']);
benefit2 = xlsread([ dataPath 'output/forbenefits2.xlsx']);
benefit3 = xlsread([ dataPath 'output/forbenefits3.xlsx']);
benefit4 = xlsread([ dataPath 'output/forbenefits4.xlsx']);


%% Figure 1: Empty seats vs Value Added
close
figure(1)
scatter(benefit1(:,1),benefit1(:,2),"MarkerFaceColor",color1 ,"MarkerEdgeColor",color1, "MarkerFaceAlpha", 0.5 )
hold on
scatter(benefit1(:,1), benefit1(:,3),"MarkerFaceColor",color2 ,"MarkerEdgeColor",color2, "MarkerFaceAlpha", 0.5 )
xlabel("Value Added")
legend("Pre-SAE", "Post-SAE", "Location","southoutside", "NumColumns", 2)
ylabel("Tasa de Vacantes Desiertas")
grid
xline(0,'--', "", 'LineWidth',0.7,'HandleVisibility','off')
box on

saveas(gcf,[figuresPath 'va_vs_empty.png'])

%% Figure 2: Maximum Capacity
close
figure(2)
subplot(1,2,1)
scatter(benefit1(:,1),benefit1(:,12),"MarkerFaceColor",color1 ,"MarkerEdgeColor",color1, "MarkerFaceAlpha", 0.5 )
xlabel("Value Added")
ylabel("Capacidad máxima por grado de entrada")
title("Pre-SAE")
grid
box on
subplot(1,2,2)
scatter(benefit1(:,1), benefit1(:,14),"MarkerFaceColor",color2 ,"MarkerEdgeColor",color2, "MarkerFaceAlpha", 0.5 )
xlabel("Value Added")
ylabel("Capacidad máxima por grado de entrada")
title("Post-SAE")
grid
box on

saveas(gcf,[figuresPath 'max_capacity.png'])


%% Figure 3: Non-Parametric Estimation
% Define range in which E(x) is going to be estimated: From min x to max x 
xrange =  [min(benefit1(:,1)) max(benefit1(:,1))];
% Define grids and window
xgrid=xrange(1):.01:xrange(2);
ygrid=NaN(length(xgrid),5);
ygridSAE=ygrid;
window=.75;
% Loop
for i=1:length(xgrid)

    pick=(xgrid(i)+window/2>benefit1(:,1) & xgrid(i)-window/2<benefit1(:,1));
    x=benefit1(pick,2);
    ygrid(i,1)=mean(x);
    ygrid(i,2)=prctile(x,10);
    ygrid(i,3)=prctile(x,90);
    ygrid(i,4)=prctile(x,50);
    ygrid(i,5)=sum(pick);

    pickSAE=(xgrid(i)+window/2>benefit1(:,1) & xgrid(i)-window/2<benefit1(:,1));
 
    xSAE=benefit1(pickSAE,3);
    ygridSAE(i,1)=mean(xSAE);
    ygridSAE(i,2)=prctile(xSAE,10);
    ygridSAE(i,3)=prctile(xSAE,90);
    ygridSAE(i,4)=prctile(xSAE,50);
    ygridSAE(i,5)=sum(pickSAE);
end
close

showObs=ygrid(:,end)>10;

figure(3)
subplot(1,2,1)
%no sae mediana
plot(xgrid(showObs),(ygrid(showObs,1)),"Color",color1, "LineWidth",2)
xlabel("Value Added")
ylabel("Tasa de Vacantes Desiertas")
hold on
%sae mediana
plot(xgrid(showObs),(ygridSAE(showObs,1)),"Color",color2,'LineWidth',2)
legend("PRE-SAE","POST-SAE")
axis tight
ylim([0 0.4])
xlim([-1.01 1.01])
grid on
%title("Vacancy Rate Conditional on Value Added")
%title("Tasa de Vacantes Desiertas Condicional en el Value Added")
subplot(1,2,2)

Delta=ygridSAE(showObs,1)-ygrid(showObs,1);

D=smooth(Delta,0.3);
hold on
h=patch([xgrid(showObs) flipud(xgrid(showObs)')'], [D' zeros(sum(showObs),1)'], 'g');
h.FaceColor=color2;
alpha(0.4)
h.EdgeColor=color2;
plot(xgrid(showObs),D,'LineWidth',2,'Color',color2)

plot(linspace(-2,2,100),zeros(100,1),":k")
hold on
plot(zeros(100,1),linspace(-2,2,100),":k")

axis tight
ylim([-0.02 0.05])
xlim([-1.01 1.01])
ylabel("Diferencia en Tasa de Vacantes Desiertas")
xlabel("Value Added")
grid on
box on
xline(-0.35,'--', "", 'LineWidth',0.7,'HandleVisibility','off')
%title("Difference in Vacancy Rate")
%title("Diferencia en Tasa de Vacantes Desiertas")

saveas(gcf,[figuresPath 'nonparam_est.png'])
xgrid2 = transpose(xgrid); 
Delta2 = ygridSAE(:,1)-ygrid(:,1);
T = table(Delta2, xgrid2);
filename = [dataPath '/intermediate/non_param_delta.xlsx'] ;
writetable(T, filename)

%% Figure 4: Benefits vs Value Added
benefit2_posvacs = benefit2(benefit2(:,2)>0,:);
benefit2_negvacs = benefit2(benefit2(:,2)<=0,:);

close
figure(4)
scatter(benefit2_posvacs(:,1),benefit2_posvacs(:,3),"MarkerFaceColor",color1 ,"MarkerEdgeColor",color1, "MarkerFaceAlpha", 0.5 )
hold on
scatter(benefit2_negvacs(:,1),benefit2_negvacs(:,3),"MarkerFaceColor",color2 ,"MarkerEdgeColor",color2, "MarkerFaceAlpha", 0.5 )
xlabel("Value Added")
legend("Más matriculados", "Menos matriculados", "Location","southoutside", "NumColumns", 2)
ylabel("Ganancias de Aprendizaje (miles de USD)")
grid
box on

saveas(gcf,[figuresPath 'benefits_vs_va.png'])

%% Figure 5: Accumulated Benefits
close 
figure(5)
plot(benefit3(:,5),benefit3(:,7),"Color",color1 , "LineWidth", 2)
xlabel("Años de Implementación de la Política")
ylabel("MUSD")
grid 
box on 
title("Ganancias de Aprendizaje Acumuladas")

saveas(gcf,[figuresPath 'benefits_acc.png'])

%% Figure 6: Empty seats vs SIMCE score (not standarized)
close 
figure(6)
scatter(benefit4(:,1), benefit4(:,3),"MarkerFaceColor",color1 ,"MarkerEdgeColor",color1, "MarkerFaceAlpha", 0.5 )
hold on
scatter(benefit4(:,1), benefit4(:,4),"MarkerFaceColor",color2 ,"MarkerEdgeColor",color2, "MarkerFaceAlpha", 0.5 )
xlabel("Promedio SIMCE")
legend("Pre-SAE", "Post-SAE", "Location","southoutside", "NumColumns", 2)
ylabel("Tasa de Vacantes Desiertas")
grid
box on

saveas(gcf,[figuresPath 'simce_vs_empty.png'])

%% Figure 7: Empty seats vs SIMCE score (standarized)
close 
figure(7)
scatter(benefit4(:,2), benefit4(:,3),"MarkerFaceColor",color1 ,"MarkerEdgeColor",color1, "MarkerFaceAlpha", 0.5 )
hold on
scatter(benefit4(:,2), benefit4(:,4),"MarkerFaceColor",color2 ,"MarkerEdgeColor",color2, "MarkerFaceAlpha", 0.5 )
xlabel("Promedio SIMCE Estandarizado")
legend("Pre-SAE", "Post-SAE", "Location","southoutside", "NumColumns", 2)
ylabel("Tasa de Vacantes Desiertas")
grid
box on

saveas(gcf,[figuresPath 'simce_vs_empty_st.png'])

%% Figure 8: Non-Parametric Estimation
% Define range in which E(x) is going to be estimated: From min x to max x 
xrange_b =  [min(benefit4(:,1)) max(benefit4(:,1))];
% Define grids and window
xgrid_b=xrange_b(1):.5:xrange_b(2);
ygrid_b=NaN(length(xgrid_b),5);
ygridSAE_b=ygrid_b;
window_b=20;
% Loop
for i=1:length(xgrid_b)

    pick_b=(xgrid_b(i)+window_b/2>benefit4(:,1) & xgrid_b(i)-window_b/2<benefit4(:,1));
    x_b=benefit4(pick_b,3);
    ygrid_b(i,1)=mean(x_b);
    ygrid_b(i,2)=prctile(x_b,10);
    ygrid_b(i,3)=prctile(x_b,90);
    ygrid_b(i,4)=prctile(x_b,50);
    ygrid_b(i,5)=sum(pick_b);

    pickSAE_b=(xgrid_b(i)+window_b/2>benefit4(:,1) & xgrid_b(i)-window_b/2<benefit4(:,1));
 
    xSAE_b=benefit4(pickSAE_b,4);
    ygridSAE_b(i,1)=mean(xSAE_b);
    ygridSAE_b(i,2)=prctile(xSAE_b,10);
    ygridSAE_b(i,3)=prctile(xSAE_b,90);
    ygridSAE_b(i,4)=prctile(xSAE_b,50);
    ygridSAE_b(i,5)=sum(pickSAE_b);
end

close
showObs_b=ygrid_b(:,end)>10;
figure(8)
subplot(1,2,1)
%no sae mediana
plot(xgrid_b(showObs),(ygrid_b(showObs,1)),"Color",color1, "LineWidth",2)
xlabel("Promedio SIMCE")
ylabel("Tasa de Vacantes Desiertas")
hold on
%sae mediana
plot(xgrid_b(showObs),(ygridSAE_b(showObs,1)),"Color",color2,'LineWidth',2)
legend("PRE-SAE","POST-SAE")
axis tight
%ylim([0 0.4])
%xlim([-1.01 1.01])
grid on
%title("Vacancy Rate Conditional on Value Added")
%title("Tasa de Vacantes Desiertas Condicional en el Value Added")
subplot(1,2,2)

Delta_b=ygridSAE_b(showObs_b,1)-ygrid_b(showObs_b,1);

D_b=smooth(Delta_b,0.3);
hold on
h_b=patch([xgrid_b(showObs_b) flipud(xgrid_b(showObs_b)')'], [D_b' zeros(sum(showObs_b),1)'], 'g');
h_b.FaceColor=color2;
alpha(0.4)
h_b.EdgeColor=color2;
plot(xgrid_b(showObs_b),D_b,'LineWidth',2,'Color',color2)
plot(linspace(225,280,100),zeros(100,1),":k")
hold on
%plot(zeros(100,1),linspace(-0.1,0.02,100),":k")

axis tight
%ylim([-0.04 0.05])
%xlim([228 280])
ylabel("Diferencia en Tasa de Vacantes Desiertas")
xlabel("Promedio SIMCE")
grid on
box on

saveas(gcf,[figuresPath 'nonparam_est_consimce.png'])

%% Figure 9: Simce + VA 
close
figure(9)
subplot(2,2,1)
%no sae mediana
plot(xgrid_b(showObs),(ygrid_b(showObs,1)),"Color",color1, "LineWidth",2)
xlabel("Promedio SIMCE")
ylabel("Tasa de Vacantes Desiertas")
hold on
%sae mediana
plot(xgrid_b(showObs),(ygridSAE_b(showObs,1)),"Color",color2,'LineWidth',2)
legend("PRE-SAE","POST-SAE")
axis tight
%ylim([0 0.4])
%xlim([-1.01 1.01])
grid on
%title("Vacancy Rate Conditional on Value Added")
%title("Tasa de Vacantes Desiertas Condicional en el Value Added")
subplot(2,2,2)

Delta_b=ygridSAE_b(showObs_b,1)-ygrid_b(showObs_b,1);

D_b=smooth(Delta_b,0.3);
hold on
h_b=patch([xgrid_b(showObs_b) flipud(xgrid_b(showObs_b)')'], [D_b' zeros(sum(showObs_b),1)'], 'g');
h_b.FaceColor=color2;
alpha(0.4)
h_b.EdgeColor=color2;
plot(xgrid_b(showObs_b),D_b,'LineWidth',2,'Color',color2)
plot(linspace(225,280,100),zeros(100,1),":k")
hold on
%plot(zeros(100,1),linspace(-0.1,0.02,100),":k")

axis tight
%ylim([-0.04 0.05])
%xlim([228 280])
ylabel("Diferencia en Tasa de Vacantes Desiertas")
xlabel("Promedio SIMCE")
grid on
box on

% CON VALUE ADDED 
subplot(2,2,3)
%no sae mediana
plot(xgrid(showObs),(ygrid(showObs,1)),"Color",color1, "LineWidth",2)
xlabel("Value Added")
ylabel("Tasa de Vacantes Desiertas")
hold on
%sae mediana
plot(xgrid(showObs),(ygridSAE(showObs,1)),"Color",color2,'LineWidth',2)
legend("PRE-SAE","POST-SAE")
axis tight
ylim([0 0.4])
xlim([-1.01 1.01])
grid on

subplot(2,2,4)
Delta=ygridSAE(showObs,1)-ygrid(showObs,1);
D=smooth(Delta,0.3);
hold on
h=patch([xgrid(showObs) flipud(xgrid(showObs)')'], [D' zeros(sum(showObs),1)'], 'g');
h.FaceColor=color2;
alpha(0.4)
h.EdgeColor=color2;
plot(xgrid(showObs),D,'LineWidth',2,'Color',color2)

plot(linspace(-2,2,100),zeros(100,1),":k")
hold on
plot(zeros(100,1),linspace(-2,2,100),":k")

axis tight
ylim([-0.02 0.05])
xlim([-1.01 1.01])
ylabel("Diferencia en Tasa de Vacantes Desiertas")
xlabel("Value Added")
grid on
box on
%xline(-0.35,'--', "", 'LineWidth',0.7,'HandleVisibility','off')


saveas(gcf,[figuresPath 'nonparam_est_both.png'])
