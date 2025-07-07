import com.vaadin.demo.views.MainLayout;
import com.vaadin.flow.component.UI;
import com.vaadin.flow.component.applayout.AppLayout;
import com.vaadin.flow.component.sidenav.SideNav;
import com.vaadin.testbench.TestBenchTestCase;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class MainLayoutTest extends TestBenchTestCase {
    @Test
    void navigationCreated() {
        MainLayout layout = new MainLayout();
        UI ui = new UI();
        ui.add(layout);
        assertTrue(layout.getContent() instanceof SideNav || layout.getChildren().anyMatch(c -> c instanceof SideNav));
    }
}
