#include "mainwindow.h"
#include "ui_mainwindow.h"
#include <QSqlQuery>
#include <QSqlError>
#include <QDebug>

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
    , model(nullptr)
{
    ui->setupUi(this);
    
    // Настройка интерфейса
    ui->tableView->setSelectionBehavior(QAbstractItemView::SelectRows);
    ui->tableView->setSelectionMode(QAbstractItemView::SingleSelection);
    
    // Подключение сигналов к слотам
    connect(ui->connectButton, &QPushButton::clicked, this, &MainWindow::connectToDatabase);
    connect(ui->tablesComboBox, QOverload<int>::of(&QComboBox::currentIndexChanged),
            this, &MainWindow::onTablesComboBoxChanged);
    connect(ui->addButton, &QPushButton::clicked, this, &MainWindow::onAddButtonClicked);
    connect(ui->deleteButton, &QPushButton::clicked, this, &MainWindow::onDeleteButtonClicked);
    connect(ui->updateButton, &QPushButton::clicked, this, &MainWindow::onUpdateButtonClicked);
    connect(ui->refreshButton, &QPushButton::clicked, this, &MainWindow::onRefreshButtonClicked);
    
    // Начальная настройка
    ui->statusLabel->setText("Не подключено к базе данных");
}

MainWindow::~MainWindow()
{
    if (model) {
        delete model;
    }
    if (db.isOpen()) {
        db.close();
    }
    delete ui;
}

void MainWindow::connectToDatabase()
{
    // Подключение к базе данных
    db = QSqlDatabase::addDatabase("QPSQL");
    db.setHostName("localhost");
    db.setDatabaseName("la_liga");
    db.setUserName("postgres");
    db.setPassword("postgres"); 
    
    if (!db.open()) {
        QMessageBox::critical(this, "Ошибка", 
            "Не удалось подключиться к базе данных:\n" + db.lastError().text());
        ui->statusLabel->setText("Ошибка подключения");
        return;
    }
    
    ui->statusLabel->setText("Подключено к la_liga");
    
    // Заполнение списка таблиц
    ui->tablesComboBox->clear();
    QStringList tables = db.tables();
    for (const QString &table : tables) {
        if (table != "spatial_ref_sys" && !table.startsWith("pg_")) {
            ui->tablesComboBox->addItem(table);
        }
    }
    
    // Активация элементов управления
    ui->tablesComboBox->setEnabled(true);
    ui->addButton->setEnabled(true);
    ui->deleteButton->setEnabled(true);
    ui->updateButton->setEnabled(true);
    ui->refreshButton->setEnabled(true);
}

void MainWindow::onTablesComboBoxChanged(int index)
{
    if (index < 0) return;
    
    currentTable = ui->tablesComboBox->currentText();
    
    // Создание модели для таблицы
    if (model) {
        delete model;
    }
    
    model = new QSqlTableModel(this, db);
    model->setTable(currentTable);
    model->setEditStrategy(QSqlTableModel::OnManualSubmit);
    
    if (!model->select()) {
        QMessageBox::critical(this, "Ошибка", 
            "Не удалось загрузить данные:\n" + model->lastError().text());
        return;
    }
    
    // Настройка отображения
    ui->tableView->setModel(model);
    ui->tableView->resizeColumnsToContents();
    
    ui->statusLabel->setText("Таблица: " + currentTable + 
                           ", записей: " + QString::number(model->rowCount()));
}

void MainWindow::onAddButtonClicked()
{
    if (!model) return;
    
    // Вставка новой пустой строки
    int row = model->rowCount();
    model->insertRow(row);
    
    // Прокрутка к новой строке
    QModelIndex index = model->index(row, 0);
    ui->tableView->scrollTo(index);
    ui->tableView->setCurrentIndex(index);
    ui->tableView->edit(index);
}

void MainWindow::onDeleteButtonClicked()
{
    if (!model) return;
    
    // Получение выбранной строки
    QModelIndexList selected = ui->tableView->selectionModel()->selectedRows();
    if (selected.isEmpty()) {
        QMessageBox::warning(this, "Предупреждение", "Выберите строку для удаления");
        return;
    }
    
    int row = selected.first().row();
    
    // Подтверждение удаления
    if (QMessageBox::question(this, "Подтверждение", 
        "Удалить выбранную запись?", 
        QMessageBox::Yes | QMessageBox::No) == QMessageBox::No) {
        return;
    }
    
    // Удаление строки
    model->removeRow(row);
    
    if (!model->submitAll()) {
        QMessageBox::critical(this, "Ошибка", 
            "Не удалось удалить запись:\n" + model->lastError().text());
        model->revertAll();
    } else {
        model->select();
        ui->statusLabel->setText("Запись удалена");
    }
}

void MainWindow::onUpdateButtonClicked()
{
    if (!model) return;
    
    // Сохранение всех изменений
    if (!model->submitAll()) {
        QMessageBox::critical(this, "Ошибка", 
            "Не удалось сохранить изменения:\n" + model->lastError().text());
        model->revertAll();
    } else {
        ui->statusLabel->setText("Изменения сохранены");
    }
}

void MainWindow::onRefreshButtonClicked()
{
    if (!model) return;
    
    model->select();
    ui->tableView->resizeColumnsToContents();
    ui->statusLabel->setText("Данные обновлены");
}