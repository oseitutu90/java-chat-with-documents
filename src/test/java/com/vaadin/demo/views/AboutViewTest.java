import com.vaadin.demo.views.AboutView;
import com.vaadin.flow.component.html.H1;
import com.vaadin.testbench.TestBenchTestCase;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class AboutViewTest extends TestBenchTestCase {
    @Test
    void containsHeader() {
        AboutView view = new AboutView();
        assertTrue(view.getComponentAt(0) instanceof H1);
    }
}
