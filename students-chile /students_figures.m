%% Intro
% Este código genera las figuras para la nota de costos de sistemas de
% asignación centralizada de estudiantes

%% Set Paths
username = 'antoniaaguilera';
if strcmp(username,'antoniaaguilera')
    Path = '/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/';
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

strColors={
'110833'
'5627FF'
'9A7DFF'
'B30AF2'
'72E8CE'
'2AC2B2'
'229B8E'
'ED175F'
'F68CAF'};

pick=[6 8 2] ;

Colors=NaN(length(strColors),3);
for i=1:length(strColors)
Colors(i,:)=sscanf(strColors{i},'%2x%2x%2x',[1 3])/255;
end

%% Satisfaction Survey 
satisfaction = readtable([dataPath 'intermediate/survey_chile_short.csv']) ;
grade = table2array(satisfaction(:,1));
percentage = table2array(satisfaction(:,2));
close 
figure(1)
bar(grade, percentage, 'FaceColor',color2, 'EdgeColor',color2, 'FaceAlpha', 0.6)
ylabel("Porcentaje")
xlabel("Nota")
title("Evaluación del Proceso de Asignación Coordinada en Chile")

saveas(gcf,[figuresPath 'satisfaction.png'])

%% Proyección a 10 años 
student_proj = readtable([dataPath '/output/students_proj_cl.xlsx']);
close 
figure(2)
year  = table2array(student_proj(:,1)) ;
cost1 = table2array(student_proj(:,2)) ;
cost2 = table2array(student_proj(:,3)) ;
cost3 = table2array(student_proj(:,4)) ;

plot(year, cost1, 'LineWidth', 2, 'Color', Colors(pick(2),:))
hold on
plot(year, cost2, 'LineWidth', 2, 'Color', Colors(pick(1),:))
plot(year, cost3,'LineWidth',  2, 'Color', Colors(pick(3),:))
hold off
xlim([1 10])
xlabel('Años desde la implementación')
ylabel('MU$D')
grid on
title('Ganancias a 10 Años')
subtitle('Asignación Centralizada de Estudiantes') 
legend('Costos', 'Ahorros', 'Beneficios (simulados)', "Location","southoutside", "NumColumns", 3)

saveas(gcf,[figuresPath 'students_proj.png'])

%% Proyección de población
student_pop = readtable([dataPath '/output/students_pop_cl.xlsx']);
year        = table2array(student_pop(:,1)) ;
total_cost1 = table2array(student_pop(:,2)) ;
applicants  = table2array(student_pop(:,3)) ; 
total_cost2 = table2array(student_pop(:,4)) ;

close 
figure(3)
plot(applicants, total_cost1, 'LineWidth', 2, 'Color', Colors(pick(2),:))
hold on
plot(applicants, total_cost2, 'LineWidth', 2, 'Color', Colors(pick(1),:))
hold off
xlim([3900, 500000])
xlabel('Número de Postulantes')
ylabel('MU$D')
grid on
title('Ahorro neto según cantidad de postulantes')
subtitle('Asignación Coordinada de Estudiantes') 
legend('Costos', 'Ahorros', "Location","southoutside", "NumColumns", 2); 

saveas(gcf,[figuresPath 'students_pop.png'])
