document.addEventListener('DOMContentLoaded', function() {
    const toggleSwitch = document.querySelector('#checkbox');
    const isSystemDark = window.matchMedia('(prefers-color-scheme: dark)');
    
    // Funksjon for å hente mørke regler og gjøre dem tilgjengelige via en klasse
    function setupDarkSheet() {
        let darkRules = "";
        for (let sheet of document.styleSheets) {
            try {
                for (let rule of sheet.cssRules) {
                    if (rule.media && rule.media.mediaText.includes('prefers-color-scheme: dark')) {
                        for (let r of rule.cssRules) {
                            // Vi pakker alle mørke regler inn i .force-dark klassen
                            darkRules += `body.force-dark ${r.cssText}\n`;
                        }
                    }
                }
            } catch (e) { /* Ignorer eksterne stilark */ }
        }

        if (darkRules) {
            const styleTag = document.createElement('style');
            styleTag.id = 'manual-dark-rules';
            styleTag.textContent = darkRules;
            document.head.appendChild(styleTag);
        }
    }

    function applyTheme(mode) {
        if (mode === 'dark') {
            document.body.classList.add('force-dark');
            document.body.classList.remove('force-light');
        } else {
            document.body.classList.add('force-light');
            document.body.classList.remove('force-dark');
        }
    }

    // Initialisering
    setupDarkSheet();
    const savedTheme = localStorage.getItem('theme');
    const startMode = savedTheme || (isSystemDark.matches ? 'dark' : 'light');

    toggleSwitch.checked = (startMode === 'dark');
    applyTheme(startMode);

    toggleSwitch.addEventListener('change', (e) => {
        const newMode = e.target.checked ? 'dark' : 'light';
        localStorage.setItem('theme', newMode);
        applyTheme(newMode);
    });
});