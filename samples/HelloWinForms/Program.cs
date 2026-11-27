// Minimal WinForms app used to prove the Windows smoke test works.
namespace HelloWinForms;

static class Program
{
    [STAThread]
    static void Main()
    {
        ApplicationConfiguration.Initialize();
        var form = new Form { Text = "Hello WinForms", Width = 420, Height = 200 };
        form.Controls.Add(new Label
        {
            Text = "Windows smoke test sample",
            Dock = DockStyle.Fill,
            TextAlign = System.Drawing.ContentAlignment.MiddleCenter,
            Font = new System.Drawing.Font("Segoe UI", 14),
        });
        Application.Run(form);
    }
}
