#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QSqlDatabase>
#include <QSqlTableModel>
#include <QMessageBox>

QT_BEGIN_NAMESPACE
namespace Ui {
class MainWindow;
}
QT_END_NAMESPACE

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

private slots:
    void onTablesComboBoxChanged(int index);
    void onAddButtonClicked();
    void onDeleteButtonClicked();
    void onUpdateButtonClicked();
    void onRefreshButtonClicked();
    void connectToDatabase();

private:
    Ui::MainWindow *ui;
    QSqlDatabase db;
    QSqlTableModel *model;
    QString currentTable;
};

#endif // MAINWINDOW_H