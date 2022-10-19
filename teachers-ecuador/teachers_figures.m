%% Intro
% Este código genera las figuras para la nota de costos de sistemas de
% asignación centralizada de estudiantes

%% Set Paths
username = 'antoniaaguilera';
if strcmp(username,'antoniaaguilera')
    Path = '/Users/antoniaaguilera/ConsiliumBots Dropbox/antoniaaguilera@consiliumbots.com/projects/iadb-ccas-costs/teachers/';
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

%% Grafico para presentación 
cost_teachers = readtable([dataPath '/output/cost_teachers_ec.xlsx']);
cost_cent   = table2array(cost_teachers(:,3)) ;
cost_cent   = cost_cent/1000000;
cost_decent = table2array(cost_teachers(:,5)) ;
cost_decent = cost_decent/1000000;
totcent     = sum(cost_cent) ;
totdecent   = sum(cost_decent) ;

%y  = [cost_cent(1,:) cost_cent(4,:) cost_cent(5,:) cost_cent(6,:) cost_cent(7,:) cost_cent(8,:) cost_cent(9,:) cost_cent(10,:) cost_cent(11,:) cost_cent(12,:) cost_cent(13,:); cost_decent(1,:) cost_decent(2,:) cost_decent(5,:) cost_decent(6,:) cost_decent(7,:) cost_decent(8,:) cost_decent(9,:) cost_decent(10,:) cost_decent(11,:) cost_decent(12,:) cost_decent(13,:)] ;
y  = [cost_cent(1,:) cost_cent(4,:) cost_cent(5,:) cost_cent(6,:) cost_cent(7,:) cost_cent(8,:) cost_cent(9,:) cost_cent(10,:) cost_cent(11,:) cost_cent(12,:) cost_cent(13,:); cost_decent(1,:) cost_decent(2,:) cost_decent(5,:) cost_decent(6,:) cost_decent(7,:) cost_decent(8,:) cost_decent(9,:) cost_decent(12,:) cost_decent(13,:)] ;

close 
figure(1)
bar(y)
%yline(totcent);
%yline(totdecent);
%text(1.5,totcent+75000,"Costo total sistema centralizado")
%text(1.5,totdecent+75000,"Costo total sistema descentralizado")
xticklabels({'Centralizado', 'Descentralizado'})
legend("Postulación","Implementación", "Mantención", "Monitoramento", "Gasto en Personal", "Materiales", "Apoyo a postulantes", "C.O Evaluación", "Costos de Evaluación para el Gobierno", "Transport", "Administración Anual", "Location","southoutside", "NumColumns", 3)
saveas(gcf,[figuresPath 'bysistema.png'])

%y2 = [cost_cent(1,:) cost_decent(1,:); cost_cent(4,:) cost_decent(4,:); cost_cent(5,:)  cost_decent(5,:); cost_cent(6,:) cost_decent(6,:); cost_cent(7,:) cost_decent(7,:) ; cost_cent(8,:) cost_decent(8,:) ; cost_cent(9,:) cost_decent(9,:); cost_cent(10,:) cost_decent(10,:); cost_cent(11,:) cost_decent(11,:) ; cost_cent(12,:) cost_decent(12,:); cost_cent(13,:) cost_decent(13,:)] ;
y2 = [cost_cent(1,:) cost_decent(1,:); cost_cent(4,:) cost_decent(4,:); cost_cent(5,:)  cost_decent(5,:); cost_cent(6,:) cost_decent(6,:); cost_cent(7,:) cost_decent(7,:) ; cost_cent(8,:) cost_decent(8,:) ; cost_cent(9,:) cost_decent(9,:); cost_cent(12,:) cost_decent(12,:); cost_cent(13,:) cost_decent(13,:)] ;

close
figure(2)
bar(y2)
%yline(totcent);
%yline(totdecent);
%text(1.5,totcent+75000,"Costo total sistema centralizado")
%text(1.5,totdecent+75000,"Costo total sistema descentralizado")
%xticklabels({'Postulación', 'Implementación', 'Mantención', 'Monitoreo', 'Gasto en Personal', 'Materiales', 'Apoyo a postulantes', 'Costos de Evaluación para los postulantes', 'Costos de Evaluación para el Gobierno', 'Transporte', 'Administración Anual'})
%xticklabels({'Aplicação', 'Implementação', 'Manutenção', 'Monitoramento', 'Gastos com pessoal', 'Materiais', 'Apoio aos candidatos', 'Custos de avaliação para os candidatos', 'Custos de avaliação para o governo', 'Transportes', 'Administração anual'})
xticklabels({'Aplicação', 'Implementação', 'Manutenção', 'Monitoramento', 'Gastos com pessoal', 'Materiais', 'Apoio aos candidatos', 'Transportes', 'Administração anual'})
legend("Centralizado", "Descentralizado","Location","northoutside", "NumColumns", 3)
ylabel('MU$D')
box on
grid on
saveas(gcf,[figuresPath 'bysistema2_portugues.png'])



%% Proyección a 10 años 
teachers_proj = readtable([dataPath '/output/teachers_proj_ec.xlsx']);
close 
figure(1)
year_proj  = table2array(teachers_proj(:,1)) ;
cost1_proj = table2array(teachers_proj(:,2)) ;
cost2_proj = table2array(teachers_proj(:,3)) ;
%cost3_proj = table2array(teachers_proj(:,4)) ;

%cost3_proj = table2array(teachers_proj(:,3)) + table2array(teachers_proj(:,5)) ;

subplot(2, 1, 1)
plot(year_proj, cost1_proj, 'LineWidth', 2, 'Color', Colors(pick(2),:))
hold on
plot(year_proj, cost2_proj, 'LineWidth', 2, 'Color', Colors(pick(1),:))
%plot(year_proj, cost3_proj,'LineWidth',  2, 'Color', Colors(pick(3),:))
hold off
xlim([1 10])
xlabel('Años desde la implementación')
%xlabel('Anos desde a implementação')
ylabel('MU$D')
ylim([0 7])
grid on
title('Ahorro neto a 10 años')
%title('Economias nos primeiros dez anos')
subtitle('Asignación Coordinada de Docentes') 
%subtitle('Alocação centralizada de professores') 
%legend('Custos', 'Economias','Benefícios (simulação)', "Location","southoutside", "NumColumns", 3)
legend('Costos', 'Ahorros', "Location","southoutside", "NumColumns", 3)
box on 
%saveas(gcf,[figuresPath 'teachers_proj_portugues.png'])

%% Proyección de población
teacher_pop = readtable([dataPath '/output/teachers_pop_ec.xlsx']);
year        = table2array(teacher_pop(:,1)) ;
total_cost1 = table2array(teacher_pop(:,2)) ;
applicants  = table2array(teacher_pop(:,3)) ; 
total_cost2 = table2array(teacher_pop(:,4)) ;

subplot(2, 1, 2)
plot(applicants, total_cost1, 'LineWidth', 2, 'Color', Colors(pick(2),:))
hold on
plot(applicants, total_cost2, 'LineWidth', 2, 'Color', Colors(pick(1),:))
hold off
xlim([1000, 20000])
xlabel('Número de Postulantes')
%xlabel('Número de candidatos')
ylabel('MU$D')
grid on
title('Ahorro neto según cantidad de postulantes')
%title('Economias de acordo com o número de candidatos')
subtitle('Asignación Coordinada de Docentes') 
%subtitle('Alocação centralizada de professores') 
legend('Costos', 'Ahorros', "Location","southoutside", "NumColumns", 2); 
%legend('Custos', 'Ahorros', "Location","southoutside", "NumColumns", 2); 
box on 

%saveas(gcf,[figuresPath 'teachers_pop_portugues.png'])
saveas(gcf,[figuresPath 'extended_analysis.png'])

%% Impacto Neto 
cost4_proj = table2array(teachers_proj(:,3)) - table2array(teachers_proj(:,2)) ;
close 
figure(3)
plot(year_proj, cost1_proj, 'LineWidth', 2, 'Color', Colors(pick(2),:))
hold on
plot(year_proj, cost4_proj, 'LineWidth', 2, 'Color', Colors(pick(3),:))
xlim([1 50])
xlabel('Años desde la implementación')
ylabel('MU$D')
ylim([0 22])
grid on
title('Ahorro neto a 10 años')
according to the number of applicants
subtitle('Asignación Coordinada de Docentes') 
legend('Costos', 'Impacto Neto', "Location","southoutside", "NumColumns", 2)
box on 
saveas(gcf,[figuresPath 'teachers_net.png'])

mean_aux = cost4_proj-cost1_proj;
x=mean(mean_aux);