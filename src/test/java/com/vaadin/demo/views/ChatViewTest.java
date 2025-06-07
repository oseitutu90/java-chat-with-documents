import com.vaadin.demo.AiAssistant;
import com.vaadin.demo.views.ChatView;
import com.vaadin.flow.component.UI;
import com.vaadin.flow.component.button.Button;
import com.vaadin.flow.component.messages.MessageInput;
import com.vaadin.flow.component.orderedlayout.VerticalLayout;
import com.vaadin.testbench.TestBenchTestCase;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
import org.mockito.Mockito;

class ChatViewTest extends TestBenchTestCase {
    @Test
    void componentsCreated() {
        AiAssistant assistant = Mockito.mock(AiAssistant.class);
        ChatView view = new ChatView(assistant);
        UI ui = new UI();
        ui.add(view);

        assertEquals(3, view.getComponentCount());
        assertTrue(view.getComponentAt(0) instanceof Button);
        assertTrue(view.getComponentAt(2) instanceof MessageInput);
    }
}
